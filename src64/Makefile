# 27mar11abu
# (c) Software Lab. Alexander Burger

.SILENT:

bin = ../bin
lib = ../lib

ifeq ($(shell uname), Linux)
	OS = Linux
	SYS = linux
	ARCH = x86-64
	AS = as
	LD-MAIN = gcc -m64 -rdynamic -lc -lm -ldl
	LD-SHARED = gcc -m64 -shared -export-dynamic
	STRIP = strip
else
ifeq ($(shell uname), SunOS)
	OS = SunOS
	SYS = sunOs
	ARCH = x86-64
	AS = gas --64
	LD-MAIN = gcc -m64 -lc -lm -ldl -lsocket -lnsl
	LD-SHARED = gcc -m64 -shared
	STRIP = strip
endif
endif

baseFiles = version.l glob.l main.l \
	gc.l apply.l flow.l sym.l subr.l big.l io.l db.l net.l err.l

picolisp: $(bin)/picolisp $(lib)/ext $(lib)/ht

all: picolisp

$(bin)/picolisp: $(ARCH).$(SYS).base.o
	mkdir -p $(bin) $(lib)
	$(LD-MAIN) -o $(bin)/picolisp $(ARCH).$(SYS).base.o
	$(STRIP) $(bin)/picolisp

$(lib)/ext: $(ARCH).$(SYS).ext.o
	$(LD-SHARED) -o $(lib)/ext $(ARCH).$(SYS).ext.o
	$(STRIP) $(lib)/ext

$(lib)/ht: $(ARCH).$(SYS).ht.o
	$(LD-SHARED) -o $(lib)/ht $(ARCH).$(SYS).ht.o
	$(STRIP) $(lib)/ht

.s.o:
	$(AS) -o $*.o $*.s


# Explicit builds for cross-assembly
x86-64.linux.base.s: $(baseFiles) sys/x86-64.linux.code.l
	./mkAsm x86-64 linux Linux base $(lib)/tags $(baseFiles) sys/x86-64.linux.code.l

x86-64.linux.ext.s: ext.l
	./mkAsm x86-64 linux Linux ext "" -fpic ext.l

x86-64.linux.ht.s: ht.l
	./mkAsm x86-64 linux Linux ht "" -fpic ht.l


x86-64.sunOs.base.s: $(baseFiles) sys/x86-64.sunOs.code.l
	./mkAsm x86-64 sunOs SunOS base $(lib)/tags $(baseFiles) sys/x86-64.sunOs.code.l

x86-64.sunOs.ext.s: ext.l
	./mkAsm x86-64 sunOs SunOS ext "" -fpic ext.l

x86-64.sunOs.ht.s: ht.l
	./mkAsm x86-64 sunOs SunOS ht "" -fpic ht.l


# Clean up
clean:
	rm -f *.s *.o

# vi:noet:ts=4:sw=4
