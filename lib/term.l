# 16mar10abu
# (c) Software Lab. Alexander Burger

### Key codes ###
(setq
   *XtF1    (in '("tput" "kf1") (line T))
   *XtF2    (in '("tput" "kf2") (line T))
   *XtF3    (in '("tput" "kf3") (line T))
   *XtF4    (in '("tput" "kf4") (line T))
   *XtF5    (in '("tput" "kf5") (line T))
   *XtF6    (in '("tput" "kf6") (line T))
   *XtF7    (in '("tput" "kf7") (line T))
   *XtF8    (in '("tput" "kf8") (line T))
   *XtF9    (in '("tput" "kf9") (line T))
   *XtF10   (in '("tput" "kf10") (line T))
   *XtF11   (in '("tput" "kf11") (line T))
   *XtF12   (in '("tput" "kf12") (line T))

   *XtMenu  "^[[29~"                            #?

   *XtIns   (in '("tput" "kich1") (line T))
   *XtDel   (in '("tput" "kdch1") (line T))

   *XtPgUp  (in '("tput" "kpp") (line T))
   *XtPgDn  (in '("tput" "knp") (line T))
   *XtUp    (in '("tput" "cuu1") (line T))
   *XtDown  "^[[B"                              #?
   *XtRight (in '("tput" "cuf1") (line T))
   *XtLeft  "^[[D"                              #?
   *XtEnd   "^[[F"                              #?
   *XtHome  (in '("tput" "home") (line T)) )


### Cursor movements ###
(de xtUp (N)
   (do N (prin *XtUp)) )

(de xtDown (N)
   (do N (prin *XtDown)) )

(de xtRight (N)
   (do N (prin *XtRight)) )

(de xtLeft (N)
   (do N (prin *XtLeft)) )

# vi:et:ts=3:sw=3
