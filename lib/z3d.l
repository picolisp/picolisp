# 03sep13abu
# (c) Software Lab. Alexander Burger

(load "@lib/native.l")

### Z-Buffer 3D library ###
(gcc "z3d" '("-L/usr/X11R6/lib" "-lXext" "-lX11")
   (z3dX (M X) z3dX NIL M (cons X 1.0))
   (z3dY (M Y) z3dY NIL M (cons Y 1.0))
   (z3dZ (M Z) z3dZ NIL M (cons Z 1.0))
   (z3dDX (M DX) z3dDX NIL M (cons DX 1.0))
   (z3dDY (M DY) z3dDY NIL M (cons DY 1.0))
   (z3dDZ (M DZ) z3dDZ NIL M (cons DZ 1.0))
   (z3dXrot (M A) z3dXrot NIL M (cons A 1.0))
   (z3dYrot (M A) z3dYrot NIL M (cons A 1.0))
   (z3dZrot (M A) z3dZrot NIL M (cons A 1.0))
   (z3dArot (M A) z3dArot NIL M (cons A 1.0))
   (z3dRotate (M X Y Z VarX VarY VarZ Flg) z3dRotate NIL
      M
      (cons X 1.0)
      (cons Y 1.0)
      (cons Z 1.0)
      (if VarX (list @ (8 . 1.0)) 0)
      (if VarY (list @ (8 . 1.0)) 0)
      (if VarZ (list @ (8 . 1.0)) 0)
      (if Flg 1 0) )
   (z3dSpot (VarX VarY X Y Z) z3dSpot NIL
      (list VarX (8 . 1.0))
      (list VarY (8 . 1.0))
      (cons X 1.0)
      (cons Y 1.0)
      (cons Z 1.0) )
   (z3dWindow (Ttl DX DY) z3dWindow 'S Ttl DX DY)
   (z3dCamera (Foc Yaw Pitch X Y Z Sky Gnd) z3dCamera NIL
      (cons Foc 1.0)
      (cons Yaw 1.0)
      (cons Pitch 1.0)
      (cons X 1.0)
      (cons Y 1.0)
      (cons Z 1.0)
      Sky
      Gnd )
   (z3dDraw (M) z3dDraw NIL M)
   (z3dPut () z3dPut)
   (z3dText (X Y S) z3dText NIL X Y S)
   (z3dSync () z3dSync) )

#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <sys/shm.h>
#include <X11/extensions/XShm.h>

#define SCL 1000000.0

typedef struct {double x, y, z;} vector;
typedef struct {vector a, b, c;} matrix;

typedef struct face {
   int col1, col2;                     // Foreground and background color
   int cnt, _x_;                       // Number of points
   vector pt[1];                       // Points
} face;

typedef struct model {
   vector pos;                         // Position
   matrix rot;                         // Orientation
   void *lst[1];                       // List of faces and submodels
} model;

typedef struct {
   int h[2];                           // Horizontal
   unsigned z[2];                      // Depth
} edge;

static double FocLen, PosX, PosY, PosZ, Pos6, Pos9;
static double Coeff1, Coeff2, Coeff4, Coeff5, Coeff6, Coeff7, Coeff8, Coeff9;

static Display *Disp;
static int Scrn;
static Colormap Cmap;
static int Dpth;
static int PixSize;
static GC Gc;
static Window Win;

static int SizX, SizY, OrgX, OrgY;
static unsigned *Zbuff;
static edge *Edges;
static XImage *Img;
static XShmSegmentInfo Info;

// (z3dX 'model 'x)
void z3dX(model *p, double x) {
   p->pos.x = x;
}

// (z3dY 'model 'y)
void z3dY(model *p, double y) {
   p->pos.y = y;
}

// (z3dZ 'model 'z)
void z3dZ(model *p, double z) {
   p->pos.z = z;
}

// (z3dDX 'model 'dx)
void z3dDX(model *p, double dx) {
   p->pos.x += dx;
}

// (z3dDY 'model 'dy)
void z3dDY(model *p, double dy) {
   p->pos.y += dy;
}

// (z3dDZ 'model 'dz)
void z3dDZ(model *p, double dz) {
   p->pos.z += dz;
}

static void xrot(matrix *p, double ca, double sa) {
   matrix m = *p;

   p->b.x = ca * m.b.x - sa * m.c.x;
   p->b.y = ca * m.b.y - sa * m.c.y;
   p->b.z = ca * m.b.z - sa * m.c.z;
   p->c.x = sa * m.b.x + ca * m.c.x;
   p->c.y = sa * m.b.y + ca * m.c.y;
   p->c.z = sa * m.b.z + ca * m.c.z;
}

static void yrot(matrix *p, double ca, double sa) {
   matrix m = *p;

   p->a.x = ca * m.a.x + sa * m.c.x;
   p->a.y = ca * m.a.y + sa * m.c.y;
   p->a.z = ca * m.a.z + sa * m.c.z;
   p->c.x = ca * m.c.x - sa * m.a.x;
   p->c.y = ca * m.c.y - sa * m.a.y;
   p->c.z = ca * m.c.z - sa * m.a.z;
}

static void zrot(matrix *p, double ca, double sa) {
   matrix m = *p;

   p->a.x = ca * m.a.x + sa * m.b.x;
   p->a.y = ca * m.a.y + sa * m.b.y;
   p->a.z = ca * m.a.z + sa * m.b.z;
   p->b.x = ca * m.b.x - sa * m.a.x;
   p->b.y = ca * m.b.y - sa * m.a.y;
   p->b.z = ca * m.b.z - sa * m.a.z;
}

// (z3dXrot 'model 'angle)
void z3dXrot(model *p, double a) {
   xrot(&p->rot, cos(a), sin(a));
}

// (z3dYrot 'model 'angle)
void z3dYrot(model *p, double a) {
   yrot(&p->rot, cos(a), sin(a));
}

// (z3dZrot 'model 'angle)
void z3dZrot(model *p, double a) {
   zrot(&p->rot, cos(a), sin(a));
}

// (z3dArot 'model 'angle)
void z3dArot(model *p, double a) {
   double n;
   vector *v;

   v = ((face*)p->lst[0])->pt;
   n = sqrt(v->x * v->x + v->y * v->y + v->z * v->z);
   v->x /= n,  v->y /= n,  v->z /= n;  // Axis unit vector
   if ((n = sqrt(v->y * v->y + v->z * v->z)) < 1.0/SCL)  // Axis parallel to x-axis
      a *= v->x,  xrot(&p->rot, cos(a), sin(a));
   else {
      xrot(&p->rot, v->z / n, -v->y / n);
      yrot(&p->rot, n, v->x);
      zrot(&p->rot, cos(a), sin(a));
      yrot(&p->rot, n, -v->x);
      xrot(&p->rot, v->z / n, v->y / n);
   }
}

// (z3dRotate 'model 'X 'Y 'Z 'varX 'varY 'varZ ['flg])
void z3dRotate(model *p, double vx, double vy, double vz,
                              double *xp, double *yp, double *zp, int flg) {
   if (!flg) {
      if (xp)
         *xp = vx * p->rot.a.x + vy * p->rot.b.x + vz * p->rot.c.x;
      if (yp)
         *yp = vx * p->rot.a.y + vy * p->rot.b.y + vz * p->rot.c.y;
      if (zp)
         *zp = vx * p->rot.a.z + vy * p->rot.b.z + vz * p->rot.c.z;
   }
   else {
      if (xp)
         *xp = vx * p->rot.a.x + vy * p->rot.a.y + vz * p->rot.a.z;
      if (yp)
         *yp = vx * p->rot.b.x + vy * p->rot.b.y + vz * p->rot.b.z;
      if (zp)
         *zp = vx * p->rot.c.x + vy * p->rot.c.y + vz * p->rot.c.z;
   }
}

// (z3dSpot 'varX 'varY 'dx 'dy 'dz)
void z3dSpot(double *xp, double *yp, double dx, double dy, double dz) {
   double d = sqrt(dx*dx + dy*dy + dz*dz);

   *xp = atan2(dy,dx);
   *yp = d < 1.0/SCL? 0.0 : asin(dz/d);
}

// (z3dWindow 'ttl 'dx 'dy) -> str
char *z3dWindow(char *ttl, int dx, int dy) {
   XPixmapFormatValues *pmFormat;
   int n, i;

   if ((Disp = XOpenDisplay(NULL)) == NULL)
      return "Can't open Display";
   Scrn = DefaultScreen(Disp);
   Cmap = DefaultColormap(Disp,Scrn);
   Dpth = PixSize = 0;
   pmFormat = XListPixmapFormats(Disp, &n);
   for (i = 0; i < n; i++) {
      if (pmFormat[i].depth == 24) {
         Dpth = 24;
         if (PixSize != 4)
            PixSize = (pmFormat[i].bits_per_pixel + 7) / 8 & ~8;
      }
      else if (pmFormat[i].depth == 16 && (PixSize < 3 || PixSize > 4)) {
         Dpth = 16;
         PixSize = (pmFormat[i].bits_per_pixel + 7) / 8 & ~8;
      }
      else if (pmFormat[i].depth == 8 && (PixSize < 2 || PixSize > 4)) {
         Dpth = 8;
         PixSize = (pmFormat[i].bits_per_pixel + 7) / 8 & ~8;
      }
   }
   if (!Dpth)
      return "Bad Display Depth";
   Gc = XCreateGC(Disp,RootWindow(Disp,Scrn), 0, NULL);

   OrgX = (SizX = dx) / 2;
   OrgY = (SizY = dy) / 2;

   /* Create Window */
   Win = XCreateSimpleWindow(Disp, RootWindow(Disp,Scrn), 0, 0, SizX, SizY,
                        1, BlackPixel(Disp,Scrn), WhitePixel(Disp,Scrn) );
   XStoreName(Disp, Win, ttl);
   XMapWindow(Disp, Win);

   /* Create Image */
   SizX = SizX + 3 & ~3;
   SizY = SizY + 3 & ~3;
   if ((Zbuff = malloc(SizX * SizY * sizeof(unsigned))) == NULL  ||
         (Edges = malloc(SizY * sizeof(edge))) == NULL )
      return "No memory";
   if (!XShmQueryExtension(Disp)  ||
         !(Img = XShmCreateImage(Disp, DefaultVisual(Disp, Scrn),
                  Dpth, ZPixmap, NULL, &Info, SizX, SizY ))  ||
         (Info.shmid = shmget(IPC_PRIVATE,
                  SizX * SizY * PixSize, IPC_CREAT | 0777 )) < 0  ||
         (Info.shmaddr = Img->data =
                           shmat(Info.shmid, 0, 0) ) == (char*)-1  ||
         !XShmAttach(Disp, &Info) )
      return "Can't create XImage";
   return NULL;
}

// (z3dCamera 'foc 'yaw 'pitch 'x 'y 'z 'sky 'gnd ['h 'v])
void z3dCamera(double foc, double yaw, double pitch,
                           double x, double y, double z, int sky, int gnd) {
   double a, sinY, cosY, sinP, cosP;
   int i, v, hor, pix;
   char *frame;

   FocLen = foc;

   sinY = sin(yaw),  cosY = cos(yaw);
   sinP = sin(pitch),  cosP = cos(pitch);
   Coeff1 = -sinY;
   Coeff2 = cosY;
   Coeff4 = cosY * sinP;
   Coeff5 = sinY * sinP;
   Coeff6 = -cosP;
   Coeff7 = cosY * cosP;
   Coeff8 = sinY * cosP;
   Coeff9 = sinP;

   PosX = x;
   PosY = y;
   PosZ = z;
   Pos6 = Coeff6 * PosZ;
   Pos9 = Coeff9 * PosZ;

   if (cosP > - 1.0/SCL  &&  cosP < 1.0/SCL)
      hor = sinP > 0.0? +16383 : -16384;
   else if ((a = FocLen * sinP/cosP) > +16383.0)
      hor = +16383;
   else if (a < -16384.0)
      hor = -16384;
   else
      hor = (int)a;

   for (v = 0; v < SizY; ++v) {
      pix  =  v < hor? sky : gnd;
      frame = Img->data + v * SizX * PixSize;
      switch (PixSize) {
      case 1:
         memset(frame, pix, SizX);
         break;
      case 2:
         pix |= pix<<16;
         i = 0;
         do
            *(int*)frame = pix,  frame += 4;
         while ((i+=2) < SizX);
         break;
      case 3:
         i = 0;
         do {
            frame[0] = pix;
            frame[1] = (pix >> 8);
            frame[2] = (pix >> 16);
            frame += 3;
         } while (++i < SizX);
         break;
      case 4:
         i = 0;
         do
            *(int*)frame = pix,  frame += 4;
         while (++i < SizX);
         break;
      }
   }
   memset(Zbuff, 0xFF, SizX * SizY * sizeof(unsigned));
}

static void rotate(vector *src, matrix *p, vector *dst) {
   dst->x = src->x * p->a.x + src->y * p->b.x + src->z * p->c.x;
   dst->y = src->x * p->a.y + src->y * p->b.y + src->z * p->c.y;
   dst->z = src->x * p->a.z + src->y * p->b.z + src->z * p->c.z;
}

static void shadowPt(double vx, double vy, int *xp, int *yp, int *zp) {
   double z;

   z = Coeff7 * vx + Coeff8 * vy - Pos9;
   *xp = (int)(FocLen * (Coeff1 * vx + Coeff2 * vy) / z);
   *yp = (int)(FocLen * (Coeff4 * vx + Coeff5 * vy - Pos6) / z);
   *zp = (int)(1000.0 * z);
}

static void transPt(double vx, double vy, double vz, int *xp, int *yp, int *zp) {
   double z;

   z = Coeff7 * vx + Coeff8 * vy + Coeff9 * vz;
   *xp = (int)(FocLen * (Coeff1 * vx + Coeff2 * vy) / z);
   *yp = (int)(FocLen * (Coeff4 * vx + Coeff5 * vy + Coeff6 * vz) / z);
   *zp = (int)(1000.0 * z);
}

static int getColor(int c) {
   XColor col;

   col.red   = c >> 8  &  0xFF00;
   col.green = c & 0xFF00;
   col.blue  = (c & 0xFF) << 8;
   col.flags = DoRed | DoGreen | DoBlue;
   XAllocColor(Disp, Cmap, &col);
   return col.pixel;
}

static void mkEdge(int x1, int y1, int z1, int x2, int y2, int z2) {
   int a, dx, dy, dz, sx, xd, xe, sz, zd, ze;
   edge *p;

   if (y2 < y1) {
      a = x1,  x1 = x2,  x2 = a;
      a = y1,  y1 = y2,  y2 = a;
      a = z1,  z1 = z2,  z2 = a;
   }
   if (y1 > OrgY  ||  ((y2 += OrgY) <= 0))
      return;
   if ((dy  =  y2 - (y1 += OrgY)) == 0)
      return;
   dx = x2 - x1,  dz = z2 - z1;
   if (y1 < 0) {
      x1 += -y1 * dx / dy;
      z1 += -y1 * dz / dy;
      y1 = 0;
      if ((dy = y2) == 0)
         return;
      dx = x2 - x1,  dz = z2 - z1;
   }
   if (y2 > SizY) {
      x2 += (SizY - y2) * dx / dy;
      z2 += (SizY - y2) * dz / dy;
      y2 = SizY;
      if ((dy = y2 - y1) == 0)
         return;
      dx = x2 - x1,  dz = z2 - z1;
   }
   sx = 0;
   if (dx > 0)
      sx = 1;
   else if (dx < 0)
      dx = -dx,  sx = -1;
   xd = 0;
   if (dx > dy)
      xd = dx/dy,  dx -= xd*dy,  xd *= sx;
   xe = (dx *= 2) - dy;
   sz = 0;
   if (dz > 0)
      sz = 1;
   else if (dz < 0)
      dz = -dz,  sz = -1;
   zd = 0;
   if (dz > dy)
      zd = dz/dy,  dz -= zd*dy,  zd *= sz;
   ze = (dz *= 2) - dy;
   dy *= 2;
   x1 += OrgX;
   p = Edges + y1;
   do {
      if ((a = x1) < 0)
         a = 0;
      else if (a > SizX)
         a = SizX;
      if (a < p->h[1]) {
         p->h[0] = a;
         p->z[0] = z1;
      }
      else {
         p->h[0] = p->h[1];
         p->z[0] = p->z[1];
         p->h[1] = a;
         p->z[1] = z1;
      }
      ++p;
      x1 += xd;
      if (xe >= 0)
         x1 += sx,  xe -= dy;
      xe += dx;
      z1 += zd;
      if (ze >= 0)
         z1 += sz,  ze -= dy;
      ze += dz;
   } while (++y1 < y2);
}

static void zDots(int i, int h, int h2, unsigned z, unsigned z2) {
   char *frame;
   unsigned *zbuff;

   i = i * SizX + h;
   frame = Img->data + i * PixSize;
   zbuff = Zbuff + i;
   i = h2 - h;
   switch (PixSize) {
   case 1:
      if (z < *zbuff)
         *zbuff = z,  *frame = 0;
      if (z2 < *(zbuff += i))
         *zbuff = z2,  *(frame + i) = 0;
      break;
   case 2:
      if (z < *zbuff)
         *zbuff = z,  *(short*)frame = (short)0;
      if (z2 < *(zbuff += i))
         *zbuff = z2,  *(short*)(frame + 2 * i) = (short)0;
      break;
   case 3:
      if (z < *zbuff) {
         *zbuff = z;
         frame[0] = 0;
         frame[1] = 0;
         frame[2] = 0;
      }
      if (z2 < *(zbuff += i)) {
         *zbuff = z2;
         frame += 3 * i;
         frame[0] = 0;
         frame[1] = 0;
         frame[2] = 0;
      }
      break;
   case 4:
      if (z < *zbuff)
         *zbuff = z,  *(int*)frame = 0;
      if (z2 < *(zbuff += i))
         *zbuff = z2,  *(int*)(frame + 4 * i) = 0;
      break;
   }
}

static void zLine(int pix, int v, int h, int h2, unsigned z, unsigned z2) {
   char *frame;
   unsigned *zbuff;
   int d, e, dh, dz, sz;

   if (dh = h2 - h) {
      v = v * SizX + h;
      frame = Img->data + v * PixSize;
      zbuff = Zbuff + v;
      sz = 0;
      if ((dz = z2 - z) > 0)
         sz = 1;
      else if (dz < 0)
         dz = -dz,  sz = -1;
      d = 0;
      if (dz > dh)
         d = dz/dh,  dz -= d*dh,  d *= sz;
      e = (dz *= 2) - dh;
      dh *= 2;
      switch (PixSize) {
      case 1:
         do {
            if (z < *zbuff)
               *zbuff = z,  *frame = pix;
            z += d;
            if (e >= 0)
               z += sz,  e -= dh;
            ++zbuff,  ++frame;
            e += dz;
         } while (++h < h2);
         break;
      case 2:
         do {
            if (z < *zbuff)
               *zbuff = z,  *(short*)frame = (short)pix;
            z += d;
            if (e >= 0)
               z += sz,  e -= dh;
            ++zbuff,  frame += 2;
            e += dz;
         } while (++h < h2);
         break;
      case 3:
         do {
            if (z < *zbuff) {
               *zbuff = z;
               frame[0] = pix;
               frame[1] = (pix >> 8);
               frame[2] = (pix >> 16);
            }
            z += d;
            if (e >= 0)
               z += sz,  e -= dh;
            ++zbuff,  frame += 3;
            e += dz;
         } while (++h < h2);
         break;
      case 4:
         do {
            if (z < *zbuff)
               *zbuff = z,  *(int*)frame = pix;
            z += d;
            if (e >= 0)
               z += sz,  e -= dh;
            ++zbuff,  frame += 4;
            e += dz;
         } while (++h < h2);
         break;
      }
   }
}

static void doDraw(model *p, matrix *r, double x, double y, double z) {
   int i, n, pix, x0, y0, z0, x1, y1, z1, x2, y2, z2;
   double dx, dy, dz;
   vector pos, pt1, pt2, pt3, v, w, nv;
   matrix rot;
   void **q;
   edge *e;

   pos = p->pos;
   rot = p->rot;
   if (!r)
      r = &rot;
   else {
      v = pos,  rotate(&v, r, &pos);
      pos.x += x,  pos.y += y,  pos.z += z;
      v = rot.a,  rotate(&v, r, &rot.a);
      v = rot.b,  rotate(&v, r, &rot.b);
      v = rot.c,  rotate(&v, r, &rot.c);
   }
   dx = pos.x - PosX;
   dy = pos.y - PosY;
   dz = pos.z - PosZ;
   /* Rough clipping */
   if ((z = Coeff7*dx + Coeff8*dy + Coeff9*dz) < 0.1)
      return;
   if (z < fabs(Coeff1*dx + Coeff2*dy))
      return;
   if (z < fabs(Coeff4*dx + Coeff5*dy + Coeff6*dz))
      return;
   /* Faces */
   for (q = p->lst; *(face**)q; ++q) {
      face *f = *(face**)q;

      if ((f->pt[0].x || f->pt[0].y || f->pt[0].z) && (f->pt[1].x || f->pt[1].y || f->pt[1].z))
         r = &rot,  rotate(f->pt, r, &pt1),  rotate(f->pt + 1, r, &pt2);
      else
         rotate(f->pt, r, &pt1),  rotate(f->pt + 1, r, &pt2),  r = &rot;
      rotate(f->pt + 2, r, &pt3);
      memset(Edges, 0, SizY * sizeof(edge));
      if (f->col2 == 0x2000000) {
         shadowPt(pt1.x + dx + pt1.z + pos.z, pt1.y + dy, &x0, &y0, &z0);
         shadowPt(pt2.x + dx + pt2.z + pos.z, pt2.y + dy, &x1, &y1, &z1);
         mkEdge(x0, y0, z0, x1, y1, z1);
         for (i = 2;;) {
            shadowPt(pt3.x + dx + pt3.z + pos.z, pt3.y + dy, &x2, &y2, &z2);
            mkEdge(x1, y1, z1, x2, y2, z2);
            if (++i == f->cnt)
               break;
            rotate(f->pt + i, r, &pt3);
            x1 = x2,  y1 = y2,  z1 = z2;
         }
         mkEdge(x2, y2, z2, x0, y0, z0);
         i = 0,  e = Edges;
         pix = getColor(0);  // Face color black
         do
            if (e->h[1])
               zLine(pix, i, e->h[0], e->h[1], e->z[0], e->z[1]);
         while (++e, ++i < SizY);
      }
      else {
         v.x = pt1.x - pt2.x;
         v.y = pt1.y - pt2.y;
         v.z = pt1.z - pt2.z;
         w.x = pt3.x - pt2.x;
         w.y = pt3.y - pt2.y;
         w.z = pt3.z - pt2.z;
         nv.x = v.y * w.z - v.z * w.y;
         nv.y = v.z * w.x - v.x * w.z;
         nv.z = v.x * w.y - v.y * w.x;
         pt1.x += dx,  pt1.y += dy,  pt1.z += dz;
         if (f->col1 == 0x1000000  &&  f->col2 == 0x1000000)
            pix = -1;  // Transparent
         else {
            if (pt1.x * nv.x + pt1.y * nv.y + pt1.z * nv.z >= 0.0) {
               if (f->col1 == 0x1000000)
                  continue;  // Backface culling
               pix = f->col1;
               n = 80 - (int)(14.14 * (nv.z-nv.x) / sqrt(nv.x*nv.x + nv.y*nv.y + nv.z*nv.z));
            }
            else {
               if (f->col2 == 0x1000000)
                  continue;  // Backface culling
               pix = f->col2;
               n = 80 + (int)(14.14 * (nv.z-nv.x) / sqrt(nv.x*nv.x + nv.y*nv.y + nv.z*nv.z));
            }
            pix = ((pix >> 16) & 255) * n / 100 << 16  |
                  ((pix >> 8) & 255) * n / 100 << 8  |  (pix & 255) * n / 100;
         }
         transPt(pt1.x, pt1.y, pt1.z, &x0, &y0, &z0);
         transPt(pt2.x + dx, pt2.y + dy, pt2.z + dz, &x1, &y1, &z1);
         mkEdge(x0, y0, z0, x1, y1, z1);
         for (i = 2;;) {
            transPt(pt3.x + dx, pt3.y + dy, pt3.z + dz, &x2, &y2, &z2);
            mkEdge(x1, y1, z1, x2, y2, z2);
            if (++i == f->cnt)
               break;
            rotate(f->pt + i, r, &pt3);
            x1 = x2,  y1 = y2,  z1 = z2;
         }
         mkEdge(x2, y2, z2, x0, y0, z0);
         i = 0,  e = Edges;
         if (pix < 0) {
            do  // Transparent
               if (e->h[1])
                  zDots(i, e->h[0], e->h[1], e->z[0], e->z[1]);
            while (++e, ++i < SizY);
         }
         else {
            pix = getColor(pix);  // Face color
            do
               if (e->h[1])
                  zLine(pix, i, e->h[0], e->h[1], e->z[0], e->z[1]);
            while (++e, ++i < SizY);
         }
      }
   }
   /* Submodels */
   while (*(model**)++q)
      doDraw(*(model**)q, &rot, pos.x, pos.y, pos.z);
}

// (z3dDraw ['model])
void z3dDraw(model *p) {
   doDraw(p, NULL, 0.0, 0.0, 0.0);
}

// (z3dPut)
void z3dPut(void) {
   XShmPutImage(Disp, Win, Gc, Img, 0, 0, 0, 0, SizX, SizY, False);
}

// (z3dText 'x 'y 'str)
void z3dText(int x, int y, char *str) {
   XDrawString(Disp, Win, Gc, x, y, str, strlen(str));
}

// (z3dSync)
void z3dSync(void) {
   XSync(Disp,False);
}

/**/

# vi:et:ts=3:sw=3
