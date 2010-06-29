# 26jun10abu
# (c) Software Lab. Alexander Burger

(and (=0 *Scl) (scl 6))                # Default scale 6

(setq                                  # Global constants
   pi    3.1415926535897932
   pi/2  1.5707963267948966 )

(load (if (== 64 64) "@lib/math64.l" "@lib/math32.l"))

# vi:et:ts=3:sw=3
