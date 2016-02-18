# 02feb16abu
# (c) Software Lab. Alexander Burger

bin = ../bin
lib = ../lib

picoFiles = main.c gc.c apply.c flow.c sym.c subr.c big.c io.c net.c tab.c

CC = gcc
# CCLD is the cc (compiler frontend) to use for the link step.
CCLD = gcc

CFLAGS = -c -O2 -pipe \
	-falign-functions=32 -fomit-frame-pointer -fno-strict-aliasing \
	-W -Wimplicit -Wreturn-type -Wunused -Wformat \
	-Wuninitialized -Wstrict-prototypes \
	-D_GNU_SOURCE  -D_FILE_OFFSET_BITS=64


ifeq ($(shell uname), Linux)
	OS = Linux
	CFLAGS += -m32
	PICOLISP-FLAGS = -m32 -rdynamic
	LIB-FLAGS = -lm -ldl
	DYNAMIC-LIB-FLAGS = -m32 -shared -export-dynamic
	LCRYPT = -lcrypt
	STRIP = strip
else
ifeq ($(shell uname), OpenBSD)
	OS = OpenBSD
	CFLAGS += -m32
	PICOLISP-FLAGS = -m32 -rdynamic -Wl,-E
	LIB-FLAGS = -lm
	DYNAMIC-LIB-FLAGS = -Wl,-E -Wl,-shared
	LCRYPT = -lcrypto
	STRIP = strip
else
ifeq ($(shell uname), FreeBSD)
	OS = FreeBSD
	CC = gcc
	CCLD = clang
	CFLAGS += -m32
	PICOLISP-FLAGS = -m32 -rdynamic
	LIB-FLAGS = -lm
	DYNAMIC-LIB-FLAGS = -m32 -shared -export-dynamic
	LCRYPT = -lcrypt
	STRIP = strip
else
ifeq ($(shell uname), NetBSD)
	OS = NetBSD
	CFLAGS += -m32
	PICOLISP-FLAGS = -m32 -rdynamic
	LIB-FLAGS = -lm
	DYNAMIC-LIB-FLAGS = -m32 -shared -export-dynamic
	LCRYPT = -lcrypto
	STRIP = strip
else
ifeq ($(shell uname), Darwin)
	OS = Darwin
	CFLAGS += -m32
	PICOLISP-FLAGS = -m32
	LIB-FLAGS = -lc -lm -ldl
	DYNAMIC-LIB-FLAGS = -m32 -dynamiclib -undefined dynamic_lookup
	LCRYPT = -lcrypto
	STRIP = strip -x
else
ifeq ($(shell uname), SunOS)
	OS = SunOS
	CFLAGS += -m32
	PICOLISP-FLAGS =
	LIB-FLAGS = -lm -lnsl -lsocket
	DYNAMIC-LIB-FLAGS = -G
	LCRYPT = -lcrypt
	STRIP = strip
else
ifeq ($(shell uname), AIX)
	OS = AIX
	CFLAGS += -maix32
	PICOLISP-FLAGS = -maix32 -Wl,-brtl -Wl,-bexpall
	LIB-FLAGS = -lm
	DYNAMIC-LIB-FLAGS = -maix32 -Wl,-G -shared -lm
	LCRYPT = -lcrypt
	STRIP = strip
else
ifeq ($(shell uname), HP-UX)
	OS = HP-UX
	CFLAGS +=
	PICOLISP-FLAGS = -m32 -rdynamic
	LIB-FLAGS = -lm -ldl
	DYNAMIC-LIB-FLAGS = -m32 -shared
	LCRYPT =
	STRIP = strip
else
ifeq ($(shell uname), IRIX64)
    OS = IRIX64
    CFLAGS += -std=gnu99
    DYNAMIC-LIB-FLAGS = -shared
    STRIP = strip -f
else
ifeq ($(shell uname -o), Cygwin)
	OS = Cygwin
	CFLAGS += -m32
	DYNAMIC-LIB-FLAGS = -shared
	PICOLISP-FLAGS =
	DLL-DEFS = $(bin)/picolisp.dll
	LCRYPT = -lcrypt
	STRIP = strip
	exe = .exe
	dll = .dll
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif


picolisp: $(bin)/picolisp $(lib)/ext$(dll) $(lib)/ht$(dll)
tools: $(bin)/lat1 $(bin)/utf2 $(bin)/balance
gate: $(bin)/ssl $(bin)/httpGate

all: picolisp tools gate

.c.o:
	$(CC) $(CFLAGS) -D_OS='"$(OS)"' $*.c


$(picoFiles:.c=.o) ext.o ht.o: pico.h
main.o: vers.h


ifeq ($(OS), Cygwin)

$(bin)/picolisp$(dll): $(picoFiles:.c=.o)
	$(CCLD) -o $(bin)/picolisp$(dll) $(DYNAMIC-LIB-FLAGS) $(picoFiles:.c=.o)
	$(STRIP) $(bin)/picolisp$(dll)

$(bin)/picolisp: $(picoFiles:.c=.o) $(bin)/picolisp$(dll) start.o
	mkdir -p $(bin) $(lib)
	$(CCLD) -o $(bin)/picolisp$(exe) $(PICOLISP-FLAGS) start.o -L$(bin) -l$(bin)/picolisp
	$(STRIP) $(bin)/picolisp$(exe)

else

$(bin)/picolisp: $(picoFiles:.c=.o)
	mkdir -p $(bin) $(lib)
	$(CCLD) -o $(bin)/picolisp$(exe) $(PICOLISP-FLAGS) $(picoFiles:.c=.o) $(LIB-FLAGS)
	$(STRIP) $(bin)/picolisp$(exe)

endif


$(lib)/ext$(dll): ext.o
	$(CCLD) -o $(lib)/ext$(dll) $(DYNAMIC-LIB-FLAGS) ext.o $(DLL-DEFS) $(LCRYPT)
	$(STRIP) $(lib)/ext$(dll)

$(lib)/ht$(dll): ht.o
	$(CCLD) -o $(lib)/ht$(dll) $(DYNAMIC-LIB-FLAGS) ht.o $(DLL-DEFS)
	$(STRIP) $(lib)/ht$(dll)


$(bin)/lat1: lat1.c
	$(CC) -o $(bin)/lat1$(exe) lat1.c
	$(STRIP) $(bin)/lat1$(exe)

$(bin)/utf2: utf2.c
	$(CC) -o $(bin)/utf2$(exe) utf2.c
	$(STRIP) $(bin)/utf2$(exe)

$(bin)/balance: balance.c
	$(CC) -o $(bin)/balance$(exe) balance.c
	$(STRIP) $(bin)/balance$(exe)

$(bin)/ssl: ssl.c
	$(CC) -o $(bin)/ssl$(exe) ssl.c -lssl -lcrypto
	$(STRIP) $(bin)/ssl$(exe)

$(bin)/httpGate: httpGate.c
	$(CC) -o $(bin)/httpGate$(exe) httpGate.c -lssl -lcrypto
	$(STRIP) $(bin)/httpGate$(exe)


# Clean up
clean:
	rm -f *.o

# vi:noet:ts=4:sw=4
