# 17oct12abu
# (c) Software Lab. Alexander Burger

(setq
   *Architecture (opt)
   *System (opt)
   *Format (opt)
   *TargetOS (opt)
   *Module (opt)
   *FPic (bool (opt)) )

(load "lib/asm.l"
   (pack "lib/fmt" *Format ".l")
   (pack "arch/" *Architecture ".l") )

(build (pack *Architecture *System "." *Module *Format) (opt)
   (load (pack "sys/" *Architecture *System ".defs.l") "defs.l" T) )

(bye)

# vi:et:ts=3:sw=3
