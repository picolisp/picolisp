# 21dec01abu
# (c) Software Lab. Alexander Burger

(setq
   *XtF1    "^[[11~"
   *XtF2    "^[[12~"
   *XtF3    "^[[13~"
   *XtF4    "^[[14~"
   *XtF5    "^[[15~"
   *XtF6    "^[[17~"
   *XtF7    "^[[18~"
   *XtF8    "^[[19~"
   *XtF9    "^[[20~"
   *XtF10   "^[[21~"
   *XtF11   "^[[23~"
   *XtF12   "^[[24~"

   *XtMenu  "^[[29~"

   *XtIns   "^[[2~"
   *XtDel   "^[[3~"

   *XtPgUp  "^[[5~"
   *XtPgDn  "^[[6~"
   *XtUp    "^[[A"
   *XtDown  "^[[B"
   *XtRight "^[[C"
   *XtLeft  "^[[D"
   *XtEnd   "^[[F"
   *XtHome  "^[[H" )

(de xtUp (N)
   (do N (prin *XtUp)) )

(de xtDown (N)
   (do N (prin *XtDown)) )

(de xtRight (N)
   (do N (prin *XtRight)) )

(de xtLeft (N)
   (do N (prin *XtLeft)) )
