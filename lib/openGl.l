# 09nov12abu
# 27jul10jk
# (c) Software Lab. Alexander Burger

### OpenGL library interface ###
(load "@lib/math.l")

(if (= *OS "Darwin")
   (default
      *GluLib "OpenGL.framework/OpenGL"
      *GlutLib "GLUT.framework/GLUT" )
   (default
      *GluLib "libGLU.so"
      *GlutLib "libglut.so" ) )

# Pre-consed fixpoint arguments
(setq
   "Flt1" (0 . -1.0)
   "Flt2" (0 . -1.0)
   "Flt3" (0 . -1.0)
   "Flt4" (0 . -1.0)
   "Dbl1" (0 . 1.0)
   "Dbl2" (0 . 1.0)
   "Dbl3" (0 . 1.0)
   "Dbl4" (0 . 1.0)
   "Dbl5" (0 . 1.0)
   "Dbl6" (0 . 1.0) )

# Utilities
(de ivect (Lst)
   (mapcar '((N) (- -4294967296 N)) Lst) )

(de fvect (Lst)
   (mapcar
      '((N) (- -4294967296 (*/ 2147483647 N 1.0)))
      Lst ) )


### /usr/include/GL/gl.h ###
### Constant Definitions ###
# Primitives
(def 'GL_POINTS         (hex "0000"))
(def 'GL_LINES          (hex "0001"))
(def 'GL_LINE_LOOP      (hex "0002"))
(def 'GL_LINE_STRIP     (hex "0003"))
(def 'GL_TRIANGLES      (hex "0004"))
(def 'GL_TRIANGLE_STRIP (hex "0005"))
(def 'GL_TRIANGLE_FAN   (hex "0006"))
(def 'GL_QUADS          (hex "0007"))
(def 'GL_QUAD_STRIP     (hex "0008"))
(def 'GL_POLYGON        (hex "0009"))

# Matrix Mode
(def 'GL_MATRIX_MODE    (hex "0BA0"))
(def 'GL_MODELVIEW      (hex "1700"))
(def 'GL_PROJECTION     (hex "1701"))
(def 'GL_TEXTURE        (hex "1702"))

# Points

# Lines
(def 'GL_LINE_SMOOTH       (hex "00000B20"))

# Polygons
(def 'GL_FRONT             (hex "0404"))
(def 'GL_CULL_FACE         (hex "00000B44"))

# Display Lists

# Depth buffer
(def 'GL_LESS              (hex "00000201"))
(def 'GL_DEPTH_TEST        (hex "00000B71"))

# Lighting
(def 'GL_LIGHTING             (hex "0B50"))
(def 'GL_LIGHT0               (hex "4000"))
(def 'GL_SPECULAR             (hex "1202"))
(def 'GL_SHININESS            (hex "1601"))
(def 'GL_POSITION             (hex "1203"))
(def 'GL_AMBIENT_AND_DIFFUSE  (hex "1602"))
(def 'GL_FRONT_AND_BACK       (hex "0408"))
(def 'GL_FLAT                 (hex "1D00"))
(def 'GL_SMOOTH               (hex "1D01"))
(def 'GL_COLOR_MATERIAL       (hex "0B57"))

# User clipping planes

# Accumulation buffer

# Alpha testing

# Blending
(def 'GL_BLEND                (hex "0BE2"))
(def 'GL_SRC_ALPHA            (hex "0302"))
(def 'GL_ONE_MINUS_SRC_ALPHA  (hex "0303"))

# Render Mode

# Feedback

# Selection

# Fog

# Logic Ops

# Stencil

# Buffers, Pixel Drawing/Reading

# Implementation limits

# Gets

# Evaluators

# Hints
(def 'GL_LINE_SMOOTH_HINT     (hex "0C52"))
(def 'GL_NICEST               (hex "1102"))

# Scissor box

# Pixel Mode / Transfer

# Texture mapping

# Utility

# Errors

# glPush/PopAttrib bits
(def 'GL_CURRENT_BIT          (hex "00000001"))
(def 'GL_POINT_BIT            (hex "00000002"))
(def 'GL_LINE_BIT             (hex "00000004"))
(def 'GL_POLYGON_BIT          (hex "00000008"))
(def 'GL_POLYGON_STIPPLE_BIT  (hex "00000010"))
(def 'GL_PIXEL_MODE_BIT       (hex "00000020"))
(def 'GL_LIGHTING_BIT         (hex "00000040"))
(def 'GL_FOG_BIT              (hex "00000080"))
(def 'GL_DEPTH_BUFFER_BIT     (hex "00000100"))
(def 'GL_ACCUM_BUFFER_BIT     (hex "00000200"))
(def 'GL_STENCIL_BUFFER_BIT   (hex "00000400"))
(def 'GL_VIEWPORT_BIT         (hex "00000800"))
(def 'GL_TRANSFORM_BIT        (hex "00001000"))
(def 'GL_ENABLE_BIT           (hex "00002000"))
(def 'GL_COLOR_BUFFER_BIT     (hex "00004000"))
(def 'GL_HINT_BIT             (hex "00008000"))
(def 'GL_EVAL_BIT             (hex "00010000"))
(def 'GL_LIST_BIT             (hex "00020000"))
(def 'GL_TEXTURE_BIT          (hex "00040000"))
(def 'GL_SCISSOR_BIT          (hex "00080000"))
(def 'GL_ALL_ATTRIB_BITS      (hex "000FFFFF"))

# Miscellaneous
(de glClearColor (Red Green Blue Alpha)
   (set "Flt1" Red  "Flt2" Green  "Flt3" Blue  "Flt4" Alpha)
   (native `*GlutLib "glClearColor" NIL "Flt1" "Flt2" "Flt3" "Flt4") )

(de glClear (Mask)
   (native `*GlutLib "glClear" NIL Mask) )

(de glBlendFunc (SFactor DFactor)
   (native `*GlutLib "glBlendFunc" NIL SFactor DFactor) )

(de glLineWidth (Width)
   (set "Flt1" Width)
   (native `*GlutLib "glLineWidth" NIL "Flt1") )

(de glEnable (Num)
   (native `*GlutLib "glEnable" NIL Num) )

(de glDisable (Num)
   (native `*GlutLib "glDisable" NIL Num) )

(de glFlush ()
   (native `*GlutLib "glFlush") )

(de glHint (Target Mode)
   (native `*GlutLib "glHint" NIL Target Mode) )

# Depth Buffer
(de glClearDepth (Depth)
   (set "Dbl1" Depth)
   (native `*GlutLib "glClearDepth" NIL "Dbl1") )

(de glDepthFunc (Num)
   (native `*GlutLib "glDepthFunc" NIL Num) )

# Accumulation Buffer

# Transformation
(de glMatrixMode (Mode)
   (native `*GlutLib "glMatrixMode" NIL Mode) )

(de glOrtho (Left Right Bottom Top Near Far)
   (set "Dbl1" Left  "Dbl2" Right  "Dbl3" Bottom  "Dbl4" Top  "Dbl5" Near  "Dbl6" Far)
   (native `*GlutLib "glOrtho" NIL "Dbl1" "Dbl2" "Dbl3" "Dbl4" "Dbl5" "Dbl6") )

(de glViewport (X Y Width Height)
   (native `*GlutLib "glViewport" NIL X Y Width Height) )

(de glPushMatrix ()
   (native `*GlutLib "glPushMatrix") )

(de glPopMatrix ()
   (native `*GlutLib "glPopMatrix") )

(de glLoadIdentity ()
   (native `*GlutLib "glLoadIdentity") )

(de glRotatef (A X Y Z)
   (set "Flt1" A  "Flt2" X  "Flt3" Y  "Flt4" Z)
   (native `*GlutLib "glRotatef" NIL "Flt1" "Flt2" "Flt3" "Flt4") )

(de glTranslatef (X Y Z)
   (set "Flt1" X  "Flt2" Y  "Flt3" Z)
   (native `*GlutLib "glTranslatef" NIL "Flt1" "Flt2" "Flt3") )

# Display Lists

# Drawing Functions
(de glBegin (Mode)
   (native `*GlutLib "glBegin" NIL Mode) )

(de glEnd ()
   (native `*GlutLib "glEnd") )

(de glVertex2f (X Y)
   (set "Flt1" X  "Flt2" Y)
   (native `*GlutLib "glVertex2f" NIL "Flt1" "Flt2") )

(de glVertex3f (X Y Z)
   (set "Flt1" X  "Flt2" Y  "Flt3" Z)
   (native `*GlutLib "glVertex3f" NIL "Flt1" "Flt2" "Flt3") )

(de glNormal3f (X Y Z)
   (set "Flt1" X  "Flt2" Y  "Flt3" Z)
   (native `*GlutLib "glNormal3f" NIL "Flt1" "Flt2" "Flt3") )

(de glColor3f (Red Green Blue)
   (set "Flt1" Red  "Flt2" Green  "Flt3" Blue)
   (native `*GlutLib "glColor3f" NIL "Flt1" "Flt2" "Flt3") )

(de glColor4f (Red Green Blue Alpha)
   (set "Flt1" Red  "Flt2" Green  "Flt3" Blue  "Flt4" Alpha)
   (native `*GlutLib "glColor4f" NIL "Flt1" "Flt2" "Flt3" "Flt4") )

# Vertex Arrays

# Lighting
(de glShadeModel (Num)
   (native `*GlutLib "glShadeModel" NIL Num) )

(de glLightiv (Light Pname Params)
   (native `*GlutLib "glLightiv" NIL Light Pname
      (cons NIL (16) (ivect Params)) ) )

(de glMaterialf (Face Pname Param)
   (set "Flt1" Param)
   (native `*GlutLib "glMaterialf" NIL Face Pname "Flt1") )

(de glMaterialfv (Face Pname Params)  # Calls 'iv' internally!
   (native `*GlutLib "glMaterialiv" NIL Face Pname
      (cons NIL (16) (fvect Params)) ) )

(de glColorMaterial (Face Mode)
   (native `*GlutLib "glColorMaterial" NIL Face Mode) )

# Raster functions

# Stenciling

# Texture mapping

# Evaluators

# Fog

# Selection and Feedback



### /usr/include/GL/glu.h ###

(de gluPerspective (Fovy Aspect ZNear ZFar)
   (set "Dbl1" Fovy  "Dbl2" Aspect  "Dbl3" ZNear  "Dbl4" ZFar)
   (native `*GluLib "gluPerspective" NIL "Dbl1" "Dbl2" "Dbl3" "Dbl4") )


### /usr/include/GL/freeglut_std.h ###
# Special key codes
(def 'GLUT_KEY_F1    1)
(def 'GLUT_KEY_F2    2)
(def 'GLUT_KEY_F3    3)
(def 'GLUT_KEY_F4    4)
(def 'GLUT_KEY_F5    5)
(def 'GLUT_KEY_F6    6)
(def 'GLUT_KEY_F7    7)
(def 'GLUT_KEY_F8    8)
(def 'GLUT_KEY_F9    9)
(def 'GLUT_KEY_F10   10)
(def 'GLUT_KEY_F11   11)
(def 'GLUT_KEY_F12   12)
(def 'GLUT_KEY_LEFT        100)
(def 'GLUT_KEY_UP          101)
(def 'GLUT_KEY_RIGHT       102)
(def 'GLUT_KEY_DOWN        103)
(def 'GLUT_KEY_PAGE_UP     104)
(def 'GLUT_KEY_PAGE_DOWN   105)
(def 'GLUT_KEY_HOME        106)
(def 'GLUT_KEY_END         107)
(def 'GLUT_KEY_INSERT      108)

# Mouse state definitions
(def 'GLUT_LEFT_BUTTON     0)
(def 'GLUT_MIDDLE_BUTTON   1)
(def 'GLUT_RIGHT_BUTTON    2)

# Display mode definitions
(def 'GLUT_RGB          (hex "0000"))
(def 'GLUT_RGBA         (hex "0000"))
(def 'GLUT_INDEX        (hex "0001"))
(def 'GLUT_SINGLE       (hex "0000"))
(def 'GLUT_DOUBLE       (hex "0002"))
(def 'GLUT_ACCUM        (hex "0004"))
(def 'GLUT_ALPHA        (hex "0008"))
(def 'GLUT_DEPTH        (hex "0010"))
(def 'GLUT_STENCIL      (hex "0020"))
(def 'GLUT_MULTISAMPLE  (hex "0080"))
(def 'GLUT_STEREO       (hex "0100"))
(def 'GLUT_LUMINANCE    (hex "0200"))

### Native functions ###
# Initialization functions
(de glutInit ()
   (native `*GlutLib "glutInit" NIL '(NIL (8) . 0)) )

(de glutInitWindowPosition (Width Height)
   (native `*GlutLib "glutInitWindowPosition" NIL Width Height) )

(de glutInitWindowSize (Width Height)
   (native `*GlutLib "glutInitWindowSize" NIL Width Height) )

(de glutInitDisplayMode (N)
   (native `*GlutLib "glutInitDisplayMode" NIL N) )

# Process loop function
(de glutMainLoop ()
   (native `*GlutLib "glutMainLoop") )

# Window management functions
(de glutCreateWindow (Name)
   (native `*GlutLib "glutCreateWindow" NIL Name) )

# Display-connected functions
(de glutPostRedisplay ()
   (native `*GlutLib "glutPostRedisplay") )

(de glutSwapBuffers ()
   (native `*GlutLib "glutSwapBuffers") )

# Mouse cursor functions

# Overlay stuff

# Menu stuff
(de createMenu (Fun)
   (native `*GlutLib "glutCreateMenu" NIL (lisp 'createMenu Fun)) )

(de glutAddMenuEntry (Name Val)
   (native `*GlutLib "glutAddMenuEntry" NIL Name Val) )

(de glutAttachMenu (Button)
   (native `*GlutLib "glutAttachMenu" NIL Button) )

# Global callback functions
(de timerFunc (Msec Fun Val)
   (native `*GlutLib "glutTimerFunc" NIL Msec (lisp 'timerFunc Fun) Val) )

# Window-specific callback functions
(de keyboardFunc (Fun)
   (native `*GlutLib "glutKeyboardFunc" NIL (lisp 'keyboardFunc Fun)) )

(de specialFunc (Fun)
   (native `*GlutLib "glutSpecialFunc" NIL (lisp 'specialFunc Fun)) )

(de reshapeFunc (Fun)
   (native `*GlutLib "glutReshapeFunc" NIL (lisp 'reshapeFunc Fun)) )

(de displayPrg Prg
   (native `*GlutLib "glutDisplayFunc" NIL (lisp 'displayPrg (cons NIL Prg))) )

(de mouseFunc (Fun)
   (native `*GlutLib "glutMouseFunc" NIL (lisp 'mouseFunc Fun)) )

(de motionFunc (Fun)
   (native `*GlutLib "glutMotionFunc" NIL (lisp 'motionFunc Fun)) )

# State setting and retrieval functions

# Font stuff

# Geometry functions
(de glutWireCube (Size)
   (set "Dbl1" Size)
   (native `*GlutLib "glutWireCube" NIL "Dbl1") )

(de glutSolidCube (Size)
   (set "Dbl1" Size)
   (native `*GlutLib "glutSolidCube" NIL "Dbl1") )

(de glutWireSphere (Radius Slices Stacks)
   (set "Dbl1" Radius)
   (native `*GlutLib "glutWireSphere" NIL "Dbl1" Slices Stacks) )

(de glutSolidSphere (Radius Slices Stacks)
   (set "Dbl1" Radius)
   (native `*GlutLib "glutSolidSphere" NIL "Dbl1" Slices Stacks) )

# Teapot rendering functions

# Game mode functions

# Video resize functions

# Colormap functions

# Misc keyboard and joystick functions

# Misc functions

# vi:et:ts=3:sw=3
