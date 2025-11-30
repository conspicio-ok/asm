NASM = nasm
CC = gcc
NASM_FLAGS = -f elf64 -g
LD_FLAGS = -no-pie -lX11

all: mathieu raphael

# Mathieu - Étape 2 : Triangle rempli avec X11
mathieu: mathieu_etape_2
	@echo "Build mathieu_etape_2 terminé. Lancez avec: make run-mathieu"

mathieu_etape_2: mathieu_etape_2.o
	$(CC) -o mathieu_etape_2 mathieu_etape_2.o $(LD_FLAGS)

mathieu_etape_2.o: mathieu_etape_2.asm
	$(NASM) $(NASM_FLAGS) mathieu_etape_2.asm

run-mathieu: mathieu_etape_2
	./mathieu_etape_2

# Raphael - Diondi : Calcul d'orientation
raphael: diondi
	@echo "Build diondi terminé. Lancez avec: make run-raphael"

diondi: diondi.o
	$(CC) -o diondi diondi.o $(LD_FLAGS)

diondi.o: diondi.asm
	$(NASM) $(NASM_FLAGS) diondi.asm

run-raphael: diondi
	./diondi

clean:
	rm -f *.o mathieu_etape_2 diondi

.PHONY: all clean mathieu raphael run-mathieu run-raphael
