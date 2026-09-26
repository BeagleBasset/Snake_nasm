TARGET = snake

ASM = nasm
LD = ld

ASMFLAGS = -f elf64

SOURCES = $(wildcard *.asm) $(wildcard utils/*.asm)
OBJECTS = $(SOURCES:.asm=.o)

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(LD) -o $@ $^

%.o: %.asm
	$(ASM) $(ASMFLAGS) -o $@ $<

utils/%.o: utils/%.asm
	$(ASM) $(ASMFLAGS) -o $@ $<

clean:
	rm -f $(OBJECTS) $(TARGET)

.PHONY: all clean
