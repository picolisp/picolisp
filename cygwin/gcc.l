# 21jan07abu
# (c) Software Lab. Alexander Burger

(de gcc (S L . @)
   (out (tmp S ".c")
      (chdir '@ (prinl "#include <pico.h>"))
      (here "/**/") )
   (call 'gcc "-c"
      "-Os" "-falign-functions" "-fomit-frame-pointer"
      "-W" "-Wimplicit" "-Wreturn-type" "-Wunused" "-Wformat"
      "-Wuninitialized" "-Wstrict-prototypes"
      "-pipe" "-D_GNU_SOURCE" "-D_FILE_OFFSET_BITS=64"
      (pack "-I" (path "@src") )
      "-o" (tmp S ".o") (tmp S ".c"))
   (apply call L 'gcc "-shared" "-o" (tmp S ".dll")
      (tmp S ".o")
      (path "@bin/picolisp.dll") )
   (while (args)
      (def (next) (def (tmp S ': (arg)))) ) )
