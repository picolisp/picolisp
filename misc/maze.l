# 21jan07abu
# (c) Software Lab. Alexander Burger

# ./p dbg.l maze.l -"setq M (maze 16 10)" -"display M"

(load "lib/simul.l")

(de maze (DX DY)
   (let Maze (grid DX DY)
      (let Fld (get Maze (rand 1 DX) (rand 1 DY))
         (recur (Fld)
            (for Dir (shuffle '((west . east) (east . west) (south . north) (north . south)))
               (with ((car Dir) Fld)
                  (unless (or (: west) (: east) (: south) (: north))
                     (put Fld (car Dir) This)
                     (put This (cdr Dir) Fld)
                     (recurse This) ) ) ) ) )
      (for Col Maze
         (for This Col
            (set This
               (cons
                  (cons (: west) (: east))
                  (cons (: south) (: north)) ) )
            (=: west)
            (=: east)
            (=: south)
            (=: north) ) )
      Maze ) )

(de display (Maze)
   (disp Maze 0 '((This) "   ")) )
