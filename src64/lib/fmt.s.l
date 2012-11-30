# 03aug12abu
# (c) Software Lab. Alexander Burger

(de newSection (Sym)
   (unless (== *Section Sym)
      (prinl)
      (prinl "   ." (setq *Section Sym)) )
   (prinl) )

# Print instruction
(de prinst (Name . @)
   (if (rest)
      (tab (3 -9 0) NIL Name (glue ", " @))
      (tab (3 -9) NIL Name) ) )

# Directives
(de label (Lbl Flg)
   (and Flg (prinl "   .globl  " Lbl))
   (prinl Lbl ':) )

(asm word (N)
   (prinst ".quad" N) )

(asm byte (N)
   (prinst ".byte" N) )

(asm bytes (Lst)
   (prinst ".byte" (glue ", " Lst)) )

(asm hx2 (Lst)
   (prinst ".short" (glue ", " (mapcar hex Lst))) )

(asm ascii (Str)
   (prinst ".ascii" (pack "\"" Str "\"")) )

(asm asciz (Str)
   (prinst ".asciz" (pack "\"" Str "\"")) )

# vi:et:ts=3:sw=3
