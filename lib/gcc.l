# 21jan07abu
# (c) Software Lab. Alexander Burger

(de gcc (S L . @)
   (out (tmp S ".c")
      (chdir '@ (prinl "#include \"" (pwd) "/src/pico.h\""))
      (here "/**/") )
   (apply call L 'gcc "-o" (tmp S)
      "-shared" "-nostartfiles" "-nostdlib" "-export-dynamic"
      "-O" "-falign-functions" "-fomit-frame-pointer"
      "-W" "-Wimplicit" "-Wreturn-type" "-Wunused" "-Wformat"
      "-Wuninitialized" "-Wstrict-prototypes"
      "-pipe" "-D_GNU_SOURCE" "-D_FILE_OFFSET_BITS=64" (tmp S ".c") )
   (while (args)
      (def (next) (def (tmp S ': (arg)))) ) )
