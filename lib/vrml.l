# 27jan00abu
# (c) Software Lab. Alexander Burger

### VRML-Output ###
(de vrml Prg
   (prinl "HTTP/1.0 200 OK")
   (prinl "Server: Pico")
   (prinl "Content-type: model/vrml")
   (prinl)
   (prinl "#VRML V2.0 utf8")
   (run Prg) )

(de shape% Prg
   (prinl "Shape {")
   (run Prg)
   (prinl "}") )

(de appearance% Prg
   (prinl "appearance Appearance {")
   (run Prg)
   (prinl "}") )

(de material% Prg
   (prinl "material Material {")
   (run Prg)
   (prinl "}") )

(de cone% Prg
   (prinl "geometry Cone {")
   (run Prg)
   (prinl "}") )
