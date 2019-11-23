all: bootrom.asm
	zmac bootrom.asm
	hex_to_coe zout/bootrom.hex bootrom.tmp
	tail -n+4 bootrom.tmp > bootrom.mem
	mv bootrom.mem ../../Multicomp80/

clean:
	rm -rf zout *.tmp *.mem
