# 17nov10abu
# (c) Software Lab. Alexander Burger

(setq *Architecture (opt)  *System (opt)  *TargetOS (opt)  *Module (opt))

(load "lib/asm.l" (pack "arch/" *Architecture ".l"))

(build (pack *Architecture "." *System "." *Module ".s") (opt)
   (load "defs.l" (pack "sys/" *System ".defs.l") T) )

(bye)

# vi:et:ts=3:sw=3
