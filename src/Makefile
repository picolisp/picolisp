# 20feb06abu
# (c) Software Lab. Alexander Burger

.SILENT:

UNAME := $(shell uname)

bin = ../bin
lib = ../lib
picoFiles = main.c gc.c apply.c flow.c sym.c subr.c big.c io.c net.c tab.c

CFLAGS := -c -O -pipe \
	-falign-functions -fomit-frame-pointer \
	-W -Wimplicit -Wreturn-type -Wunused -Wformat \
	-Wuninitialized -Wstrict-prototypes \
	-D_GNU_SOURCE  -D_FILE_OFFSET_BITS=64


ifeq ($(UNAME),Linux)
	PICOLISP-FLAGS = -rdynamic -lc -lm -ldl
	DYNAMIC-LIB-FLAGS = -shared -nostartfiles -nostdlib -export-dynamic
	STRIP = strip
endif
ifeq ($(UNAME),FreeBSD)
	PICOLISP-FLAGS = -rdynamic -lc -lm
	DYNAMIC-LIB-FLAGS = -shared -nostartfiles -nostdlib -export-dynamic
	STRIP = strip
endif
ifeq ($(UNAME),Darwin)
	export MACOSX_DEPLOYMENT_TARGET=10.4
	PICOLISP-FLAGS = -lc -lm -ldl
	DYNAMIC-LIB-FLAGS = -dynamiclib -undefined dynamic_lookup -nostartfiles -export-dynamic
	STRIP = :
endif


# all: picolisp gate x11

picolisp: $(bin)/picolisp $(lib)/ext $(lib)/ht $(lib)/z3d $(bin)/lat1 $(bin)/utf2 $(bin)/balance
gate: $(bin)/ssl $(bin)/httpGate
x11: $(bin)/z3dClient

.c.o:
	echo $*.c:
	gcc $(CFLAGS) $*.c


$(picoFiles:.c=.o) ext.o ht.o z3d.o: pico.h

$(bin)/picolisp: $(picoFiles:.c=.o)
	mkdir -p $(bin) $(lib) ../tmp ../fifo
	echo "  " link picolisp:
	gcc -o $(bin)/picolisp $(PICOLISP-FLAGS) $(picoFiles:.c=.o)
	$(STRIP) $(bin)/picolisp

$(lib)/ext: ext.o
	echo "  " link ext:
	gcc -o $(lib)/ext $(DYNAMIC-LIB-FLAGS) ext.o
	$(STRIP) $(lib)/ext

$(lib)/ht: ht.o
	echo "  " link ht:
	gcc -o $(lib)/ht $(DYNAMIC-LIB-FLAGS) ht.o
	$(STRIP) $(lib)/ht

$(lib)/z3d: z3d.o
	echo "  " link z3d:
	gcc -o $(lib)/z3d  $(DYNAMIC-LIB-FLAGS) z3d.o
	$(STRIP) $(lib)/z3d


$(bin)/lat1: lat1.o
	echo "  " link lat1:
	gcc -o $(bin)/lat1 lat1.o
	$(STRIP) $(bin)/lat1

$(bin)/utf2: utf2.o
	echo "  " link utf2:
	gcc -o $(bin)/utf2 utf2.o
	$(STRIP) $(bin)/utf2

$(bin)/balance: balance.o
	echo "  " link balance:
	gcc -o $(bin)/balance balance.o
	$(STRIP) $(bin)/balance

$(bin)/ssl: ssl.o
	echo "  " link ssl:
	gcc -o $(bin)/ssl ssl.o -lssl -lcrypto
	$(STRIP) $(bin)/ssl

$(bin)/httpGate: httpGate.o
	echo "  " link httpGate:
	gcc -o $(bin)/httpGate httpGate.o -lssl -lcrypto
	$(STRIP) $(bin)/httpGate

$(bin)/z3dClient: z3dClient.o
	echo "  " link z3dClient:
	gcc -o $(bin)/z3dClient z3dClient.o  -L/usr/X11R6/lib -lXext -lX11
	$(STRIP) $(bin)/z3dClient


# Clean up
clean:
	rm -f *.o
