# 05dec16abu
# (c) Software Lab. Alexander Burger

bin = ../bin
lib = ../lib

ifeq ($(MAKECMDGOALS), arm64.linux)
	UNAME = Linux
	MACHINE = arm64
else
	ifeq ($(MAKECMDGOALS), x86-64.linux)
		UNAME = Linux
		MACHINE = x86_64
	else
		ifeq ($(MAKECMDGOALS), ppc64.linux)
			UNAME = Linux
			MACHINE = ppc64le
		else
			ifeq ($(MAKECMDGOALS), x86-64.freeBsd)
				UNAME = FreeBSD
				MACHINE = x86_64
			else
				ifeq ($(MAKECMDGOALS), x86-64.openBsd)
					UNAME = OpenBSD
					MACHINE = x86_64
				else
					ifeq ($(MAKECMDGOALS), x86-64.sunOs)
						UNAME = SunOS
						MACHINE = x86_64
					else
						UNAME = $(shell uname)
						ifeq ($(MAKECMDGOALS), emu)
							MACHINE = emu
						else
							MACHINE = $(shell uname -m)
						endif
					endif
				endif
			endif
		endif
	endif
endif

SYS =
PIE =
FMT = .c
ARCH = emu
STRIP = :

ifeq ($(UNAME), Linux)
	OS = Linux
	ifeq ($(MACHINE), arm64)
		SYS = .linux
		FMT = .s
		ARCH = arm64
		AS = as
	else
		ifeq ($(MACHINE), x86_64)
			SYS = .linux
			FMT = .s
			ARCH = x86-64
			## PIE = -no-pie
			AS = as
		else
			ifeq ($(MACHINE), ppc64le)
				SYS = .linux
				FMT = .s
				ARCH = ppc64
				AS = as -mppc64 -a64 -mlittle
			endif
		endif
	endif
	LD-MAIN = -Wl,--no-as-needed -rdynamic -lc -lm -ldl
	LD-SHARED = -shared -export-dynamic
	STRIP = strip
else
	ifeq ($(UNAME), FreeBSD)
		OS = FreeBSD
		SYS = .freeBsd
		FMT = .s
		ARCH = x86-64
		AS = as
		LD-MAIN = -Wl,--no-as-needed -rdynamic -lc -lm
		LD-SHARED = -shared -rdynamic
		STRIP = strip
	else
		ifeq ($(UNAME), OpenBSD)
			OS = OpenBSD
			SYS = .openBsd
			FMT = .s
			ARCH = x86-64
			AS = as
			LD-MAIN = -Wl,-nopie -rdynamic -lc -lm
			LD-SHARED = -shared -rdynamic
			STRIP = strip
		else
			ifeq ($(UNAME), SunOS)
				OS = SunOS
				SYS = .sunOs
				FMT = .s
				ARCH = x86-64
				AS = gas --64
				LD-MAIN = -m64 -lc -lm -ldl -lsocket -lnsl
				LD-SHARED = -m64 -shared
				STRIP = strip
			endif
		endif
	endif
endif

baseFiles = version.l glob.l main.l \
	gc.l apply.l flow.l sym.l subr.l big.l io.l db.l net.l err.l

sFiles = \
	$(ARCH)$(SYS).base$(FMT) \
	$(ARCH)$(SYS).ext$(FMT) \
	$(ARCH)$(SYS).ht$(FMT)

all: picolisp

arm64.linux: $(sFiles)
x86-64.linux: $(sFiles)
ppc64.linux: $(sFiles)
x86-64.freeBsd: $(sFiles)
x86-64.openBsd: $(sFiles)
x86-64.sunOs: $(sFiles)
emu: picolisp

picolisp: $(bin)/picolisp $(lib)/ext $(lib)/ht

### Link ###
$(bin)/picolisp: $(ARCH)$(SYS).base.o
	$(CC) -o $(bin)/picolisp $(ARCH)$(SYS).base.o $(LD-MAIN) $(PIE)
	$(STRIP) $(bin)/picolisp

$(lib)/ext: $(ARCH)$(SYS).ext.o
	$(CC) -o $(lib)/ext $(ARCH)$(SYS).ext.o $(LD-SHARED)
	$(STRIP) $(lib)/ext

$(lib)/ht: $(ARCH)$(SYS).ht.o
	$(CC) -o $(lib)/ht $(ARCH)$(SYS).ht.o $(LD-SHARED)
	$(STRIP) $(lib)/ht

### Assemble ###
.s.o:
	$(AS) -o $*.o $*.s

### Compile ###
sysdefs: sysdefs.c
	$(CC) -o sysdefs -D_FILE_OFFSET_BITS=64 sysdefs.c
	$(STRIP) sysdefs

emu.base.o: sysdefs emu.base.c
	$(CC) -c -O -fomit-frame-pointer -D_FILE_OFFSET_BITS=64 emu.base.c

.c.o:
	$(CC) -c -O -fpic -fomit-frame-pointer -D_FILE_OFFSET_BITS=64 $*.c

### Translate ###
$(ARCH)$(SYS).base$(FMT): arch/$(ARCH).l defs.l $(baseFiles) sys/$(ARCH)$(SYS).code.l
	./mkAsm $(ARCH) "$(SYS)" $(FMT) $(OS) base "" $(lib)/map  $(baseFiles) sys/$(ARCH)$(SYS).code.l

$(ARCH)$(SYS).ext$(FMT): arch/$(ARCH).l defs.l ext.l $(ARCH)$(SYS).base$(FMT)
	./mkAsm $(ARCH) "$(SYS)" $(FMT) $(OS) ext T ""  ext.l

$(ARCH)$(SYS).ht$(FMT): arch/$(ARCH).l defs.l ht.l $(ARCH)$(SYS).base$(FMT)
	./mkAsm $(ARCH) "$(SYS)" $(FMT) $(OS) ht T ""  ht.l

### Clean up ###
clean:
	rm -f emu.*.c *.s *.o *.symtab sysdefs

# vi:noet:ts=4:sw=4
