TARGET = grabfmc udprtx

all: $(TARGET)

grabfmc: grabfmc.c
	gcc -Wall -o $@ $<

udprtx: udprtx.c
	gcc -Wall -o $@ $<

clean:
	rm -f $(TARGET) *.dat
