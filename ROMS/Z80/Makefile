bootrom = z80UARTMonitor

all: $(bootrom).asm
	zasm -uxyw --z80 $(bootrom).asm -o $(bootrom).hex
	hex_to_coe $(bootrom).hex $(bootrom).tmp
	tail -n+4 $(bootrom).tmp > bootrom.mem
	mv bootrom.mem ../../Multicomp80/

clean:
	rm -f *.hex *.lst *.mem *.rom *.tmp
