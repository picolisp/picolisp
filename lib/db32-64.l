# 05feb10abu
# (c) Software Lab. Alexander Burger

## 1. On the 32-bit system, in single-user mode:
##    : (load "lib/db32-64.l")
##    : (export64 *Pool *Dbs *Blob)
##
## 2. Transfer the resulting file "db64.tgz" to the 64-bit system,
##    and unpack it in the application's runtime directory
##
## 3. On the 64-bit system, in single-user mode:
##    : (load "lib/db32-64.l")
##    : (import32)

# 64-bit DB export: (export64 "db/app/" *Dbs *Blob) -> "db64.tgz"
(de export64 (Pool Dbs Blob)
   (if Blob
      (call 'tar "cfz" (tmp "db32.tgz") Pool Blob)
      (call 'tar "cfz" (tmp "db32.tgz") Pool) )
   (chdir (tmp)
      (call 'tar "xfz" "db32.tgz")
      (pool Pool Dbs)
      (for (F . @) (or Dbs (2))
         (for (S (seq F)  S  (seq S))
            (touch S)
            (at (0 . 10000) (commit T)) ) )
      (commit T)
      (pool)
      (for (F . @) Dbs
         (call 'mv
            (pack Pool F)
            (pack Pool (hax (dec F))) ) )
      (ifn Blob
         (call 'tar "cvfz" "../../db64.tgz" Pool)
         (call 'mv Blob ".blob/")
         (call 'mkdir "-p" Blob)
         (use (@S @R Src)
            (let Pat '`(conc (chop ".blob/") '(@S "." @R))
               (in (list 'find ".blob/" "-type" "f")
                  (while (setq Src (line))
                     (when (match Pat Src)
                        (let
                           (L (split (replace @S "/") "-")
                              Dbf
                              (when (cdr L)
                                 (pack
                                    (hax (dec (fmt64 (pack (pop 'L)))))
                                    "/" ) )
                              Id
                              (chop (oct (fmt64 (pack (car L)))))
                              Dst
                              (pack
                                 Blob
                                 Dbf
                                 (car Id)
                                 (flip
                                    (mapcan list
                                       (flip (cdr Id))
                                       '(NIL NIL "/" .) ) )
                                 "."
                                 @R ) )
                           (when (dirname Dst)
                              (call 'mkdir "-p" @) )
                           (call 'mv Src Dst) ) ) ) ) ) )
         (call 'tar "cvfz" "../../db64.tgz" Pool Blob) ) ) )

# 32-bit -> 64-bit DB import
(de import32 ()
   (dbMap NIL
      '((Base Root Var Cls Hook)
         (rebuild NIL Var Cls Hook) ) ) )

# vi:et:ts=3:sw=3
