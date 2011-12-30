# 01nov11abu
# (c) Software Lab. Alexander Burger

.SILENT:

bin = ../bin
lib = ../lib

ifneq ($(filter x86-64.linux, $(MAKECMDGOALS)),)
	UNAME = Linux
	MACHINE = x86_64
else
	ifneq ($(filter x86-64.sunOs, $(MAKECMDGOALS)),)
		UNAME = SunOS
		MACHINE = x86_64
	else
      ifneq ($(filter ppc64.linux, $(MAKECMDGOALS)),)
         UNAME = Linux
         MACHINE = ppc64
      else
         UNAME = $(shell uname)
         MACHINE = $(shell uname -m)
      endif
	endif
endif

ifeq ($(UNAME), Linux)
	OS = Linux
	SYS = linux
	ifeq ($(MACHINE), x86_64)
		ARCH = x86-64
		MKASM-BASE =
		MKASM-LIB = -fpic
		AS = as
	else
	ifeq ($(MACHINE), ppc64)
		ARCH = ppc64
		MKASM-BASE = -'prSym "ppc64.symtab"'
		MKASM-LIB = -fpic -'rdSym "ppc64.symtab"'
		AS = as -mppc64 -a64
	endif
	endif
	LD-MAIN = -m64 -rdynamic -lc -lm -ldl
	LD-SHARED = -m64 -shared -export-dynamic
	STRIP = strip
else
ifeq ($(UNAME), SunOS)
	OS = SunOS
	SYS = sunOs
	ARCH = x86-64
	MKASM-BASE =
	MKASM-LIB = -fpic
	AS = gas --64
	LD-MAIN = -m64 -lc -lm -ldl -lsocket -lnsl
	LD-SHARED = -m64 -shared
	STRIP = strip
endif
endif

baseFiles = version.l glob.l main.l \
	gc.l apply.l flow.l sym.l subr.l big.l io.l db.l net.l err.l

sFiles = $(ARCH).$(SYS).base.s $(ARCH).$(SYS).ext.s $(ARCH).$(SYS).ht.s

all: picolisp

x86-64.linux: $(sFiles)
x86-64.sunOs: $(sFiles)
ppc64.linux: $(sFiles)

picolisp: $(bin)/picolisp $(lib)/ext $(lib)/ht

$(bin)/picolisp: $(ARCH).$(SYS).base.o
	mkdir -p $(bin) $(lib)
	gcc -o $(bin)/picolisp $(ARCH).$(SYS).base.o -Wl,--no-as-needed $(LD-MAIN)
	$(STRIP) $(bin)/picolisp

$(lib)/ext: $(ARCH).$(SYS).ext.o
	gcc -o $(lib)/ext $(ARCH).$(SYS).ext.o $(LD-SHARED)
	$(STRIP) $(lib)/ext

$(lib)/ht: $(ARCH).$(SYS).ht.o
	gcc -o $(lib)/ht $(ARCH).$(SYS).ht.o $(LD-SHARED)
	$(STRIP) $(lib)/ht

.s.o:
	$(AS) -o $*.o $*.s


# Explicit builds for cross-assembly
$(ARCH).$(SYS).base.s: lib/asm.l arch/$(ARCH).l $(baseFiles) sys/$(ARCH).$(SYS).code.l
	./mkAsm $(ARCH) $(SYS) $(OS) base $(lib)/map $(baseFiles) sys/$(ARCH).$(SYS).code.l $(MKASM-BASE)

$(ARCH).$(SYS).ext.s: lib/asm.l arch/$(ARCH).l ext.l $(ARCH).$(SYS).base.s
	./mkAsm $(ARCH) $(SYS) $(OS) ext "" $(MKASM-LIB) ext.l

$(ARCH).$(SYS).ht.s: lib/asm.l arch/$(ARCH).l ht.l $(ARCH).$(SYS).base.s
	./mkAsm $(ARCH) $(SYS) $(OS) ht "" $(MKASM-LIB) ht.l


# Clean up
clean:
	rm -f *.s *.o *.symtab

# vi:noet:ts=4:sw=4
