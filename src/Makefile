# 04oct10abu
# 27feb08rdo
# (c) Software Lab. Alexander Burger

bin = ../bin
lib = ../lib

picoFiles = main.c gc.c apply.c flow.c sym.c subr.c big.c io.c net.c tab.c

CFLAGS := -c -O2 -m32 -pipe \
	-falign-functions -fomit-frame-pointer -fno-strict-aliasing \
	-W -Wimplicit -Wreturn-type -Wunused -Wformat \
	-Wuninitialized -Wstrict-prototypes \
	-D_GNU_SOURCE  -D_FILE_OFFSET_BITS=64


ifeq ($(shell uname), Linux)
	OS = Linux
	PICOLISP-FLAGS = -m32 -rdynamic
	LIB-FLAGS = -lc -lm -ldl
	DYNAMIC-LIB-FLAGS = -m32 -shared -export-dynamic
	STRIP = strip
else
ifeq ($(shell uname), OpenBSD)
	OS = OpenBSD
	PICOLISP-FLAGS = -m32 -rdynamic -Wl,-E
	LIB-FLAGS = -lc -lm
	DYNAMIC-LIB-FLAGS = -Wl,-E -Wl,-shared
	STRIP = strip
else
ifeq ($(shell uname), FreeBSD)
	OS = FreeBSD
	PICOLISP-FLAGS = -m32 -rdynamic
	LIB-FLAGS = -lc -lm
	DYNAMIC-LIB-FLAGS = -m32 -shared -export-dynamic
	STRIP = strip
else
ifeq ($(shell uname), NetBSD)
	OS = NetBSD
	PICOLISP-FLAGS = -m32 -rdynamic
	LIB-FLAGS = -lc -lm
	DYNAMIC-LIB-FLAGS = -m32 -shared -export-dynamic
	STRIP = strip
else
ifeq ($(shell uname), Darwin)
	OS = Darwin
	PICOLISP-FLAGS = -m32
	LIB-FLAGS = -lc -lm -ldl
	DYNAMIC-LIB-FLAGS = -m32 -dynamiclib -undefined dynamic_lookup
	STRIP = :
else
ifeq ($(shell uname -o), Cygwin)
	OS = Cygwin
	DYNAMIC-LIB-FLAGS = -shared
	PICOLISP-FLAGS =
	DLL-DEFS = $(bin)/picolisp.dll
	STRIP = strip
	exe = .exe
	dll = .dll
endif
endif
endif
endif
endif
endif


picolisp: $(bin)/picolisp $(lib)/ext$(dll) $(lib)/ht$(dll) $(lib)/z3d$(dll)
tools: $(bin)/lat1 $(bin)/utf2 $(bin)/balance
gate: $(bin)/ssl $(bin)/httpGate
x11: $(bin)/z3dClient

all: picolisp tools gate x11

.c.o:
	gcc $(CFLAGS) -D_OS='"$(OS)"' $*.c


$(picoFiles:.c=.o) ext.o ht.o z3d.o: pico.h


ifeq ($(OS), Cygwin)

$(bin)/picolisp$(dll): $(picoFiles:.c=.o)
	gcc -o $(bin)/picolisp$(dll) $(DYNAMIC-LIB-FLAGS) $(picoFiles:.c=.o)
	$(STRIP) $(bin)/picolisp$(dll)

$(bin)/picolisp: $(picoFiles:.c=.o) $(bin)/picolisp$(dll) start.o
	mkdir -p $(bin) $(lib)
	gcc -o $(bin)/picolisp$(exe) $(PICOLISP-FLAGS) start.o -L$(bin) -l$(bin)/picolisp
	$(STRIP) $(bin)/picolisp$(exe)

else

$(bin)/picolisp: $(picoFiles:.c=.o)
	mkdir -p $(bin) $(lib)
	gcc -o $(bin)/picolisp$(exe) $(PICOLISP-FLAGS) $(picoFiles:.c=.o) $(LIB-FLAGS)
	$(STRIP) $(bin)/picolisp$(exe)

endif


$(lib)/ext$(dll): ext.o
	gcc -o $(lib)/ext$(dll) $(DYNAMIC-LIB-FLAGS) ext.o $(DLL-DEFS)
	$(STRIP) $(lib)/ext$(dll)

$(lib)/ht$(dll): ht.o
	gcc -o $(lib)/ht$(dll) $(DYNAMIC-LIB-FLAGS) ht.o $(DLL-DEFS)
	$(STRIP) $(lib)/ht$(dll)

$(lib)/z3d$(dll): z3d.o
	gcc -o $(lib)/z3d$(dll)  $(DYNAMIC-LIB-FLAGS) z3d.o $(DLL-DEFS)
	$(STRIP) $(lib)/z3d$(dll)


$(bin)/lat1: lat1.c
	gcc -o $(bin)/lat1$(exe) lat1.c
	$(STRIP) $(bin)/lat1$(exe)

$(bin)/utf2: utf2.c
	gcc -o $(bin)/utf2$(exe) utf2.c
	$(STRIP) $(bin)/utf2$(exe)

$(bin)/balance: balance.c
	gcc -o $(bin)/balance$(exe) balance.c
	$(STRIP) $(bin)/balance$(exe)

$(bin)/ssl: ssl.c
	gcc -o $(bin)/ssl$(exe) ssl.c -lssl -lcrypto
	$(STRIP) $(bin)/ssl$(exe)

$(bin)/httpGate: httpGate.c
	gcc -o $(bin)/httpGate$(exe) httpGate.c -lssl -lcrypto
	$(STRIP) $(bin)/httpGate$(exe)

$(bin)/z3dClient: z3dClient.c
	gcc -o $(bin)/z3dClient$(exe) z3dClient.c  -L/usr/X11R6/lib -lXext -lX11
	$(STRIP) $(bin)/z3dClient$(exe)


# Clean up
clean:
	rm -f *.o

# vi:noet:ts=4:sw=4
