# 02feb16abu
# (c) Software Lab. Alexander Burger

(de gcc (S L . @)
   (out (tmp S ".c")
      (chdir '@ (prinl "#include \"" (pwd) "/src/pico.h\""))
      (here "/**/") )
   ~(case *OS
      (("Linux" "FreeBSD" "NetBSD" "OpenBSD")
         (quote
            (apply call L "gcc" "-m32" "-o" (tmp S)
               "-shared" "-export-dynamic"
               "-O" "-falign-functions" "-fomit-frame-pointer"
               "-W" "-Wimplicit" "-Wreturn-type" "-Wunused" "-Wformat"
               "-Wuninitialized" "-Wstrict-prototypes"
               "-pipe" "-D_GNU_SOURCE" "-D_FILE_OFFSET_BITS=64" (tmp S ".c") ) ) )
      (("SunOS" "HP-UX")
         (quote
            (apply call L "gcc" "-o" (tmp S)
               "-shared" "-fPIC"
               "-O" "-falign-functions" "-fomit-frame-pointer"
               "-W" "-Wimplicit" "-Wreturn-type" "-Wunused" "-Wformat"
               "-Wuninitialized" "-Wstrict-prototypes"
               "-pipe" "-D_GNU_SOURCE" "-D_FILE_OFFSET_BITS=64" (tmp S ".c") ) ) )
      ("IRIX64"
         (quote
            (apply call L "gcc" "-o" (tmp S)
               "-shared"
               "-O" "-falign-functions" "-fomit-frame-pointer"
               "-W" "-Wimplicit" "-Wreturn-type" "-Wunused" "-Wformat"
               "-Wuninitialized" "-Wstrict-prototypes"
               "-pipe" "-D_GNU_SOURCE" "-D_FILE_OFFSET_BITS=64" (tmp S ".c") ) ) )
      ("AIX"
         (quote
            (apply call L "gcc" "-o" (tmp S)
               "-shared" "-Wl,-G"
               "-O" "-falign-functions" "-fomit-frame-pointer"
               "-W" "-Wimplicit" "-Wreturn-type" "-Wunused" "-Wformat"
               "-Wuninitialized" "-Wstrict-prototypes"
               "-pipe" "-D_GNU_SOURCE" "-D_FILE_OFFSET_BITS=64" (tmp S ".c") ) ) )
      ("Darwin"
         (quote
            (apply call L "gcc" "-o" (tmp S)
               "-dynamiclib" "-undefined" "dynamic_lookup"
               "-O" "-falign-functions" "-fomit-frame-pointer"
               "-W" "-Wimplicit" "-Wreturn-type" "-Wunused" "-Wformat"
               "-Wuninitialized" "-Wstrict-prototypes"
               "-pipe" "-D_GNU_SOURCE" "-D_FILE_OFFSET_BITS=64" (tmp S ".c") ) ) )
      ("Cygwin"
         (quote
            (call "gcc" "-c"
               "-Os" "-falign-functions" "-fomit-frame-pointer"
               "-W" "-Wimplicit" "-Wreturn-type" "-Wunused" "-Wformat"
               "-Wuninitialized" "-Wstrict-prototypes"
               "-pipe" "-D_GNU_SOURCE" "-D_FILE_OFFSET_BITS=64"
               (pack "-I" (path "@src") )
               "-o" (tmp S ".o") (tmp S ".c"))
            (apply call L "gcc" "-shared" "-o" (tmp S ".dll")
               (tmp S ".o")
               (path "@bin/picolisp.dll") ) ) ) )
   (while (args)
      (def (next) (def (tmp S ': (arg)))) ) )

# vi:et:ts=3:sw=3
