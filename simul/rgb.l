# 02sep99abu
# (c) Software Lab. Alexander Burger

(de rgb (R G B . S)
   (def S (+ B (* G 256) (* R 65536))) )

# Color Constant Definitions from "/usr/lib/X11/rgb.txt"
(rgb 0     0   0 . Black)
(rgb 0     0 255 . Blue)
(rgb 165  42  42 . Brown)
(rgb 0   100   0 . DarkGreen)
(rgb 169 169 169 . DarkGrey)
(rgb 190 190 190 . Grey)
(rgb 173 216 230 . LightBlue)
(rgb 211 211 211 . LightGrey)
(rgb 255   0   0 . Red)
(rgb 46  139  87 . SeaGreen)
(rgb 255 255   0 . Yellow)

(rgb 255 193 193 . RosyBrown1)
(rgb 238 180 180 . RosyBrown2)
(rgb 205 155 155 . RosyBrown3)
(rgb 139 105 105 . RosyBrown4)

(rgb 221 160 221 . Plum)
(rgb 135 206 250 . LightSkyBlue)
(rgb 245 222 179 . Wheat)
(rgb 255 255 255 . White)
(rgb 139   0   0 . DarkRed)
