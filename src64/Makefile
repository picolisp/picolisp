# 16jun11abu
# (c) Software Lab. Alexander Burger

.SILENT:

bin = ../bin
lib = ../lib

ifeq ($(shell uname), Linux)
	OS = Linux
	SYS = linux
	ifeq ($(shell uname -m), x86_64)
		ARCH = x86-64
		AS = as
	else
	ifeq ($(shell uname -m), ppc64)
		ARCH = ppc64
		AS = as -mppc64 -a64
	endif
	endif
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
x86-64.linux.base.s: lib/asm.l arch/x86-64.l $(baseFiles) sys/x86-64.linux.code.l
	./mkAsm x86-64 linux Linux base $(lib)/tags $(baseFiles) sys/x86-64.linux.code.l

x86-64.linux.ext.s: lib/asm.l arch/x86-64.l ext.l
	./mkAsm x86-64 linux Linux ext "" -fpic ext.l

x86-64.linux.ht.s: lib/asm.l arch/x86-64.l ht.l
	./mkAsm x86-64 linux Linux ht "" -fpic ht.l


ppc64.linux.base.s: lib/asm.l arch/ppc64.l $(baseFiles) sys/ppc64.linux.code.l
	./mkAsm ppc64 linux Linux base $(lib)/tags $(baseFiles) sys/ppc64.linux.code.l -'prSym "ppc64.symtab"'

ppc64.linux.ext.s: lib/asm.l arch/ppc64.l ext.l ppc64.linux.base.s
	./mkAsm ppc64 linux Linux ext "" -fpic -'rdSym "ppc64.symtab"' ext.l

ppc64.linux.ht.s: lib/asm.l arch/ppc64.l ht.l ppc64.linux.base.s
	./mkAsm ppc64 linux Linux ht "" -fpic -'rdSym "ppc64.symtab"' ht.l


x86-64.sunOs.base.s: lib/asm.l arch/x86-64.l $(baseFiles) sys/x86-64.sunOs.code.l
	./mkAsm x86-64 sunOs SunOS base $(lib)/tags $(baseFiles) sys/x86-64.sunOs.code.l

x86-64.sunOs.ext.s: lib/asm.l arch/x86-64.l ext.l
	./mkAsm x86-64 sunOs SunOS ext "" -fpic ext.l

x86-64.sunOs.ht.s: lib/asm.l arch/x86-64.l ht.l
	./mkAsm x86-64 sunOs SunOS ht "" -fpic ht.l


# Clean up
clean:
	rm -f *.s *.o

# vi:noet:ts=4:sw=4
