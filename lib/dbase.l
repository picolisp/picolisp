# 08nov03abu
# (c) Software Lab. Alexander Burger

(de dbase (File)
   (use (Cnt Hdr Siz Fld X)
      (in File
         (unless (= 3 (rd 1))    # Version
            (quit "dBASE Version") )
         (rd 3)                  # Date
         (setq
            Cnt (rd -4)          # Record count
            Hdr (rd -2)          # Header size
            Siz (rd -2) )        # Record size
         (rd 3)                  # Reserved
         (unless (=0 (rd 1))     # Encryption Flag
            (quit "Encrypted") )
         (rd 16)                 # Reserved
         (setq Fld
            (make
               (until (= 13 (setq X (rd 1)))
                  (link
                     (cons
                        (intern                    # Name
                           (pack
                              (char X)
                              (make
                                 (for
                                    (L (make (do 10 (link (rd 1))))
                                       (n0 (car L))
                                       (cdr L) )
                                    (link (char (car L))) ) ) ) )
                        (cons
                           (char (rd 1))           # Type
                           (cons
                              (prog (rd 4) (rd 1)) # Size
                              (rd 1) ) ) ) )       # Prec
                  (rd 14) ) ) ) )  # Skip

      (in (list "bin/utf2" "-dd" (pack "if=" File) (pack "bs=" Hdr) "skip=1")
         (prog1
            (make
               (do Cnt
                  (setq X (make (do Siz (link (char)))))
                  (when (<> "*" (pop 'X))
                     (link
                        (mapcan
                           '((F)
                              (when (clip (cut (caddr F) 'X))
                                 (let S
                                    (pack
                                       (replace @  # DOS German Umlauts
                                          `(char 132) `(char 228)       # ae
                                          `(char 148) `(char 246)       # oe
                                          `(char 129) `(char 252)       # ue
                                          `(char 142) `(char 196)       # AE
                                          `(char 153) `(char 214)       # OE
                                          `(char 154) `(char 220)       # UE
                                          `(char 225) `(char 223) ) )   # sz
                                    (cons
                                       (cons
                                          (car F)
                                          (case (cadr F)
                                             ("C" S)
                                             ("D" ($dat S))
                                             ("L" (bool (member S `(chop "JjTt"))))
                                             ("N" (format S (cdddr F)))
                                             (T "?") ) ) ) ) ) )
                           Fld ) ) ) ) )
            (unless (= "^Z" (char))
               (quit "Missing EOF") ) ) ) ) )
