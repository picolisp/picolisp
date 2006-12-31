# 28dec06abu
# (c) Software Lab. Alexander Burger

bin = ../bin
lib = ../lib

picoFiles = main.c gc.c apply.c flow.c sym.c subr.c big.c io.c net.c tab.c

CFLAGS := -c -O3 -pipe \
	-falign-functions -fomit-frame-pointer \
	-W -Wimplicit -Wreturn-type -Wunused -Wformat \
	-Wuninitialized -Wstrict-prototypes \
	-D_GNU_SOURCE  -D_FILE_OFFSET_BITS=64


ifeq ($(shell uname), Linux)
	PICOLISP-FLAGS = -rdynamic -lc -lm -ldl
	DYNAMIC-LIB-FLAGS = -shared -nostartfiles -nostdlib -export-dynamic
	STRIP = strip
else
ifeq ($(shell uname), FreeBSD)
	PICOLISP-FLAGS = -rdynamic -lc -lm
	DYNAMIC-LIB-FLAGS = -shared -nostartfiles -nostdlib -export-dynamic
	STRIP = strip
else
ifeq ($(shell uname), Darwin)
	export MACOSX_DEPLOYMENT_TARGET=10.4
	PICOLISP-FLAGS = -lc -lm -ldl
	DYNAMIC-LIB-FLAGS = -dynamiclib -undefined dynamic_lookup -nostartfiles -export-dynamic
	STRIP = :
else
ifeq ($(shell uname -o), Cygwin)
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


picolisp: $(bin)/picolisp $(lib)/ext$(dll) $(lib)/ht$(dll) $(lib)/z3d$(dll)
tools: $(bin)/lat1 $(bin)/utf2 $(bin)/balance
gate: $(bin)/ssl $(bin)/httpGate
x11: $(bin)/z3dClient

all: picolisp tools gate x11

.c.o:
	@echo $*.c:
	gcc $(CFLAGS) $*.c


$(picoFiles:.c=.o) ext.o ht.o z3d.o: pico.h


ifeq ($(shell uname -o), Cygwin)

$(bin)/picolisp$(dll): $(picoFiles:.c=.o) 
	@echo "  " picolisp shared library $(dll):
	gcc -o $(bin)/picolisp$(dll) $(DYNAMIC-LIB-FLAGS) $(picoFiles:.c=.o) 
	$(STRIP) $(bin)/picolisp$(dll)

$(bin)/picolisp: $(picoFiles:.c=.o) $(bin)/picolisp$(dll) start.o
	mkdir -p $(bin) $(lib)
	@echo "  " link picolisp:
	gcc -o $(bin)/picolisp$(exe) $(PICOLISP-FLAGS) start.o -L$(bin) -l$(bin)/picolisp
	$(STRIP) $(bin)/picolisp$(exe)

else

$(bin)/picolisp: $(picoFiles:.c=.o)
	mkdir -p $(bin) $(lib)
	@echo "  " link picolisp:
	gcc -o $(bin)/picolisp$(exe) $(PICOLISP-FLAGS) $(picoFiles:.c=.o)
	$(STRIP) $(bin)/picolisp$(exe)

endif


$(lib)/ext$(dll): ext.o
	@echo "  " link ext:
	gcc -o $(lib)/ext$(dll) $(DYNAMIC-LIB-FLAGS) ext.o $(DLL-DEFS)
	$(STRIP) $(lib)/ext$(dll)

$(lib)/ht$(dll): ht.o
	@echo "  " link ht:
	gcc -o $(lib)/ht$(dll) $(DYNAMIC-LIB-FLAGS) ht.o $(DLL-DEFS)
	$(STRIP) $(lib)/ht$(dll)

$(lib)/z3d$(dll): z3d.o
	@echo "  " link z3d:
	gcc -o $(lib)/z3d$(dll)  $(DYNAMIC-LIB-FLAGS) z3d.o $(DLL-DEFS)
	$(STRIP) $(lib)/z3d$(dll)


$(bin)/lat1: lat1.o
	@echo "  " link lat1:
	gcc -o $(bin)/lat1$(exe) lat1.o
	$(STRIP) $(bin)/lat1$(exe)

$(bin)/utf2: utf2.o
	@echo "  " link utf2:
	gcc -o $(bin)/utf2$(exe) utf2.o
	$(STRIP) $(bin)/utf2$(exe)

$(bin)/balance: balance.o
	@echo "  " link balance:
	gcc -o $(bin)/balance$(exe) balance.o
	$(STRIP) $(bin)/balance$(exe)

$(bin)/ssl: ssl.o
	@echo "  " link ssl:
	gcc -o $(bin)/ssl$(exe) ssl.o -lssl -lcrypto
	$(STRIP) $(bin)/ssl$(exe)

$(bin)/httpGate: httpGate.o
	@echo "  " link httpGate:
	gcc -o $(bin)/httpGate$(exe) httpGate.o -lssl -lcrypto
	$(STRIP) $(bin)/httpGate$(exe)

$(bin)/z3dClient: z3dClient.o
	@echo "  " link z3dClient:
	gcc -o $(bin)/z3dClient$(exe) z3dClient.o  -L/usr/X11R6/lib -lXext -lX11
	$(STRIP) $(bin)/z3dClient$(exe)


# Clean up
clean:
	rm -f *.o
