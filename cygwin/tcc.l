# 13jan16abu
# (c) Software Lab. Alexander Burger

# use the Tiny C Compiler http://fabrice.bellard.free.fr/tcc
(de tcc (S L . @)
   (out (tmp S ".c")
      (chdir '@ (prinl "#include <pico.h>"))
      (here "/**/") )
   (apply call L "tcc" "-shared" "-rdynamic"
      (pack "-I" (dospath "/usr/include"))
      (pack "-I" (dospath (path "@/src")))
      "-falign-functions" "-fomit-frame-pointer"
      "-W" "-Wimplicit" "-Wreturn-type" "-Wunused" "-Wformat"
      "-Wuninitialized" "-Wstrict-prototypes" "-pipe"
      "-D_GNU_SOURCE" "-D_FILE_OFFSET_BITS=64" "-DNOWAIT"
      "-o" (tmp S ".dll") (tmp S ".c")
      (dospath (path "@/bin/picolisp.def")))
   (while (args)
      (def (next) (def (tmp S ': (arg)))) ) )

(de dospath (p)
   (in '("cygpath" "-m" p) (line T)) )
