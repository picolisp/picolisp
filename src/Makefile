# 11dec02abu
# (c) Software Lab. Alexander Burger

.SILENT:

bin = ../bin

# all: pico gate x11

pico: $(bin)/pico ../ext ../z3d $(bin)/lat1 $(bin)/utf2
gate: $(bin)/ssl $(bin)/httpGate
x11: $(bin)/z3dClient

picoFiles = main.c gc.c io.c flow.c big.c sym.c subr.c apply.c tab.c net.c

.c.o:
	echo $*.c:
	gcc -c -O3 -fomit-frame-pointer \
	-W -Wimplicit -Wreturn-type -Wunused -Wformat \
	-Wuninitialized -Wstrict-prototypes \
	-pipe  -D "ID='G'"  $*.c


$(bin)/pico: $(picoFiles:.c=.o)
	rm -f ../pico
	mkdir -p $(bin)
	echo "  " link pico:
	gcc  -rdynamic  -o $(bin)/pico  $(picoFiles:.c=.o)  -lc -lm -ldl
	strip $(bin)/pico

../ext: ext.o
	echo "  " link ext:
	gcc -shared -nostartfiles -nostdlib -export-dynamic \
		-o ../ext  ext.o
	strip ../ext

../z3d: z3d.o
	echo "  " link z3d:
	gcc -shared -nostartfiles -nostdlib -export-dynamic \
		-o ../z3d  z3d.o
	strip ../z3d

$(bin)/lat1: lat1.o
	echo "  " link lat1:
	gcc -o $(bin)/lat1 lat1.o
	strip $(bin)/lat1

$(bin)/utf2: utf2.o
	echo "  " link utf2:
	gcc -o $(bin)/utf2 utf2.o
	strip $(bin)/utf2

$(bin)/ssl: ssl.o
	echo "  " link ssl:
	gcc -o $(bin)/ssl ssl.o -lssl -lcrypto
	strip $(bin)/ssl

$(bin)/httpGate: httpGate.o
	echo "  " link httpGate:
	gcc -o $(bin)/httpGate httpGate.o -lssl -lcrypto
	strip $(bin)/httpGate

$(bin)/z3dClient: z3dClient.o
	echo "  " link z3dClient:
	gcc -o $(bin)/z3dClient z3dClient.o  -L/usr/X11/lib -lXext -lX11
	strip $(bin)/z3dClient


# Clean up
clean:
	rm -f *.o
