bootrom = z80UARTMonitor

all: $(bootrom).asm
	zasm -uxyw --z80 $(bootrom).asm -o $(bootrom).hex
	hex_to_coe $(bootrom).hex 4096 | tail -n+4 > ../../Multicomp80/bootrom.mem

clean:
	rm -f *.hex *.lst *.mem *.rom *.tmp
