;*****************************************************************************
; XR - Xmodem Receive for Z80 CP/M 2.2 using CON:
; Copyright 2017 Mats Engstrom, SmallRoomLabs
;
; Licensed under the MIT license
;*****************************************************************************
;
;	Common entry points and locations
;
BDOS:	EQU 	0005h	; BDOS function vector
DFCB:	EQU	5CH	; Default File Control Block
DFCBcr:	EQU 	DFCB+32 ; Current record

;
; BDOS function codes
;
WRTSEQ:  EQU	21	; Write Sequential DE=FCBaddr A<status (00ok)
PUTDMA:	 EQU	26	; Set DMA Address DE=addr

;
; ASCII codes
;
LF:	EQU	'J'-40h	; ^J LF
CR: 	EQU 	'M'-40h	; ^M CR/ENTER
SOH:	EQU	'A'-40h	; ^A CTRL-A
EOT:	EQU	'D'-40h	; ^D = End of Transmission
ACK:	EQU	'F'-40h	; ^F = Positive Acknowledgement
NAK:	EQU	'U'-40h	; ^U = Negative Acknowledgement
CAN:	EQU	'X'-40h	; ^X = Cancel

;
; Start of code
;
xmodemrecv:
	ld	DE,msgHeader	; Print a greeting
	call otext

	ld 	A,1		; The first packet is number 1
	ld 	(pktNo),A
	ld 	A,255-1		; Also store the 1-complement of it
	ld 	(pktNo1c),A

GetNewPacket:
	ld	A,20		; We retry 20 times before giving up
	ld 	(retrycnt),A

NPloop:
	ld 	A,5		; 5 Seconds of timeout before each new block
	call	GetCharTmo
	jp 	NC,NotPacketTimeout

	ld	HL,retrycnt	; Reached max number of retries?
	dec 	(HL)
	jp 	Z,Failure	; Yes, print message and exit

	ld 	C,NAK		; Send a NAK to the uploader
	call	CONOUT
	jp 	NPloop

NotPacketTimeout:
	cp	EOT		; Did uploader say we're finished?
	jp	Z,Done		; Yes, then we're done
	cp 	CAN		; Uploader wants to abort transfer?
	jp 	Z,Cancelled	; Yes, then we're also done
	cp	SOH		; Did we get a start-of-new-packet?
	jp	NZ,NPloop	; No, go back and try again

	ld	HL,packet	; Save the received char into the...
	ld	(HL),A		; ...packet buffer and...
	inc 	HL		; ...point to the next location
	push 	HL

	ld 	B,131		; Get 131 more characters for a full packet
GetRestOfPacket:
	push 	BC
	ld 	A,1
	call	GetCharTmo
	pop 	BC

	pop	HL		; Save the received char into the...
	ld	(HL),A		; ...packet buffer and...
	inc 	HL		; ...point to the next location
	push 	HL

	djnz	GetRestOfPacket

	ld	HL,packet+3	; Calculate checksum from 128 bytes of data
	ld	B,128
	ld	A,0
csloop:	add	A,(HL)		; Just add up the bytes
	inc	HL
	djnz	csloop

	xor	(HL)		; HL points to the received checksum so
	jp	NZ,Failure	; by xoring it to our sum we check for equality

	ld	A,(pktNo)	; Check if agreement of packet numbers
	ld	C,A
	ld	A,(packet+1)
	cp	C
	jp	NZ,Failure

	ld	A,(pktNo1c)	; Check if agreement of 1-compl packet numbers
	ld	C,A
	ld	A,(packet+2)
	cp	C
	jp	NZ,Failure

	; memcpy()
	; INPUT: DE = src, HL = dst, BC = len
	;
	; mul() - multiple adds
	; INPUT: THE VALUES IN REGISTER B EN C
	; OUTPUT: HL = B * E
	;
	LD HL, 0
	LD D, 0
	LD E, 128
	LD A, (pktNo)		; pktNo is always >= 1
	LD B, A
memcpyloop:
	ADD HL,DE
	DJNZ memcpyloop
	; end of MUL
	LD DE, 0x1000		; dummy dest ptr
	ADD HL, DE			; HL = memcpy dst
	LD DE, packet+3		; DE = memcpy src
	LD B, 0
	LD C, 128			; BC = memcpy len
	LDIR
	; done memcpy

	ld	HL,pktNo	; Update the packet counters
	inc 	(HL)
	ld	HL,pktNo1c
	dec	(HL)

	ld 	C,ACK		; Tell uploader that we're happy with with
	call	CONOUT		; packet and go back and fetch some more
	jp	GetNewPacket

Done:
	ld	C,ACK		; Tell uploader we're done
	call	CONOUT
	ld 	DE,msgSucces1	; Print success message and filename
	call	otext
	;call	PrintFilename - print file memory location? context? hash?
	ld 	DE,msgSucces2
	call 	otext
	jp	Exit

Failure:
	ld 	DE,msgFailure
	jp	Die

Cancelled:
	ld 	DE,msgCancel
	jp	Die

Die:
	call 	otext	; Prints message and exits from program
Exit:
	ld	SP,(oldSP)
	ret


;
; Waits for up to A seconds for a character to become available and
; returns it in A without echo and Carry clear. If timeout then Carry
; it set.
;
GetCharTmo:
	ld 	B,A
GCtmoa:
	push	BC
	ld	B,255
GCtmob:
	push	BC
	ld	B,255
GCtmoc:
	push	BC
	call	CONST
	cp	00h		; A char available?
	jp 	NZ,GotChar	; Yes, get out of loop
	ld	HL,(0)		; Waste some cycles
	ld	HL,(0)		; ...
	ld	HL,(0)		; ...
	ld	HL,(0)		; ...
	ld	HL,(0)		; ...
	ld	HL,(0)		; ...
	pop	BC
	djnz	GCtmoc
	pop	BC
	djnz	GCtmob
	pop	BC
	djnz	GCtmoa
	scf 			; Set carry signals timeout
	ret

GotChar:
	pop	BC
	pop	BC
	pop	BC
	call	CONIN
	or 	A 		; Clear Carry signals success
	ret


;
; BIOS jump table vectors to be patched
;
CONST:	jp 	0ff06h	; A=0 if no character is ready, 0FFh if one is
CONIN:	jp	0ff09h	; Wait until character ready available and return in A
CONOUT:	jp	0ff0ch	; Write the character in C to the screen

;
; Message strings
;
msgHeader: DB 	'CP/M XR - Xmodem receive v0.1 / SmallRoomLabs 2017',CR,LF,0
msgFailure:DB	CR,LF,'Transmssion failed',CR,LF,0
msgCancel: DB	CR,LF,'Transmission cancelled',CR,LF,0
msgSucces1:DB	CR,LF,'File ',0
msgSucces2:DB	' received successfully',CR,LF,0

;
; Variables
;
oldSP:	 DS	2	; The orginal SP to be restored before exiting
retrycnt:DS 	1	; Counter for retries before giving up
chksum:	 DS	1	; For claculating the ckecksum of the packet
pktNo:	 DS 	1 	; Current packet Number
pktNo1c: DS 	1 	; Current packet Number 1-complemented
packet:	 DS 	1	; SOH
	 DS	1	; PacketN
	 DS	1	; -PacketNo,
	 DS	128	; data*128,
	 DS	1 	; chksum

stack:	 DS 	256
stackend: EQU $

	END
