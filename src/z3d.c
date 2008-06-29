/* 22apr08abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

#define SCL 1000000.0

typedef struct {double x, y, z;} vector;
typedef struct {vector a, b, c;} matrix;

static bool Snap;
static int SnapD, Snap1h, Snap1v, Snap2h, Snap2v;
static double FocLen, PosX, PosY, PosZ, Pos6, Pos9, SnapX, SnapY, SnapZ;
static double Coeff1, Coeff2, Coeff4, Coeff5, Coeff6, Coeff7, Coeff8, Coeff9;


static any getVector(any lst, vector *dst) {
   dst->x = numToDouble(car(lst)) / SCL,  lst = cdr(lst);
   dst->y = numToDouble(car(lst)) / SCL,  lst = cdr(lst);
   dst->z = numToDouble(car(lst)) / SCL;
   return cdr(lst);
}

static any putVector(vector *src, any lst) {
   car(lst) = doubleToNum(src->x * SCL),  lst = cdr(lst);
   car(lst) = doubleToNum(src->y * SCL),  lst = cdr(lst);
   car(lst) = doubleToNum(src->z * SCL);
   return cdr(lst);
}

static any getMatrix(any lst, matrix *dst) {
   return getVector(getVector(getVector(lst, &dst->a), &dst->b), &dst->c);
}

static any putMatrix(matrix *src, any lst) {
   return putVector(&src->c, putVector(&src->b, putVector(&src->a, lst)));
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

// (z3d:Xrot 'angle 'model) -> T
any Xrot(any ex) {
   any x;
   double a;
   matrix m;

   a = evDouble(ex, x = cdr(ex)) / SCL;
   x = EVAL(cadr(x));
   Touch(ex,x);
   x = cdddr(val(x));
   getMatrix(x, &m),  xrot(&m, cos(a), sin(a)),  putMatrix(&m, x);
   return T;
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

// (z3d:Yrot 'angle 'model) -> T
any Yrot(any ex) {
   any x;
   double a;
   matrix m;

   a = evDouble(ex, x = cdr(ex)) / SCL;
   x = EVAL(cadr(x));
   Touch(ex,x);
   x = cdddr(val(x));
   getMatrix(x, &m),  yrot(&m, cos(a), sin(a)),  putMatrix(&m, x);
   return T;
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

// (z3d:Zrot 'angle 'model) -> T
any Zrot(any ex) {
   any x;
   double a;
   matrix m;

   a = evDouble(ex, x = cdr(ex)) / SCL;
   x = EVAL(cadr(x));
   Touch(ex,x);
   x = cdddr(val(x));
   getMatrix(x, &m),  zrot(&m, cos(a), sin(a)),  putMatrix(&m, x);
   return T;
}

// (z3d:Arot 'angle 'model) -> T
any Arot(any ex) {
   any x;
   double a, n;
   matrix m;
   vector pt;

   a = evDouble(ex, x = cdr(ex)) / SCL;
   x = EVAL(cadr(x));
   Touch(ex,x);
   x = cdddr(val(x));
   getVector(cddar(getMatrix(x, &m)), &pt);
   n = sqrt(pt.x*pt.x + pt.y*pt.y + pt.z*pt.z);
   pt.x /= n,  pt.y /= n,  pt.z /= n;  // Axis unit vector
   if ((n = sqrt(pt.y*pt.y + pt.z*pt.z)) == 0.0)  // Axis parallel to x-axis
      a *= pt.x,  xrot(&m, cos(a), sin(a));
   else {
      xrot(&m, pt.z/n, -pt.y/n);
      yrot(&m, n, pt.x);
      zrot(&m, cos(a), sin(a));
      yrot(&m, n, -pt.x);
      xrot(&m, pt.z/n, pt.y/n);
   }
   putMatrix(&m, x);
   return T;
}

// (z3d:Rotate 'X 'Y 'Z 'model 'varX 'varY 'varZ ['flg]) -> T
any Rotate(any ex) {
   any x;
   double vx, vy, vz;
   matrix m;
   cell c1, c2, c3;

   vx = evDouble(ex, x = cdr(ex)) / SCL;
   vy = evDouble(ex, x = cdr(x)) / SCL;
   vz = evDouble(ex, x = cdr(x)) / SCL;
   x = cdr(x),  getMatrix(cdddr(val(EVAL(car(x)))), &m);
   x = cdr(x),  Push(c1, EVAL(car(x)));
   NeedVar(ex,data(c1));
   x = cdr(x),  Push(c2, EVAL(car(x)));
   NeedVar(ex,data(c2));
   x = cdr(x),  Push(c3, EVAL(car(x)));
   NeedVar(ex,data(c3));
   if (isNil(EVAL(cadr(x)))) {
      if (!isNil(data(c1)))
         val(data(c1)) = doubleToNum((vx * m.a.x + vy * m.b.x + vz * m.c.x) * SCL);
      if (!isNil(data(c2)))
         val(data(c2)) = doubleToNum((vx * m.a.y + vy * m.b.y + vz * m.c.y) * SCL);
      if (!isNil(data(c3)))
         val(data(c3)) = doubleToNum((vx * m.a.z + vy * m.b.z + vz * m.c.z) * SCL);
   }
   else {
      if (!isNil(data(c1)))
         val(data(c1)) = doubleToNum((vx * m.a.x + vy * m.a.y + vz * m.a.z) * SCL);
      if (!isNil(data(c2)))
         val(data(c2)) = doubleToNum((vx * m.b.x + vy * m.b.y + vz * m.b.z) * SCL);
      if (!isNil(data(c3)))
         val(data(c3)) = doubleToNum((vx * m.c.x + vy * m.c.y + vz * m.c.z) * SCL);
   }
   drop(c1);
   return T;
}

static void _approach(any ex, double d, any dst, any src) {
   any l1, l2;
   int i;
   double n;

   Touch(ex,dst);
   l1 = val(dst);
   Fetch(ex,src);
   l2 = val(src);
   for (i = 0;  i < 12;  ++i) {
      n = numToDouble(car(l1)) / SCL;
      car(l1) = doubleToNum((n + d * (numToDouble(car(l2)) / SCL - n)) * SCL);
      l1 = cdr(l1),  l2 = cdr(l2);
   }
   do {
      while (!isSym(car(l1)))
         if (!isCell(l1 = cdr(l1)))
            return;
      while (!isSym(car(l2)))
         if (!isCell(l2 = cdr(l2)))
            return;
      _approach(ex, d, car(l1), car(l2));
   } while (isCell(l1 = cdr(l1))  &&  isCell(l2 = cdr(l2)));
}

// (z3d:Approach 'num 'model 'model) -> T
any Approach(any ex) {
   any x;
   long n;
   cell c1, c2;

   n = evCnt(ex, x = cdr(ex));
   x = cdr(x),  Push(c1, EVAL(car(x)));
   x = cdr(x),  Push(c2, EVAL(car(x)));
   _approach(ex, 1.0 / (double)n, data(c1), data(c2));
   drop(c1);
   return T;
}

// (z3d:Spot 'dx 'dy 'dz ['x 'y 'z]) -> (yaw . pitch)
any Spot(any ex) {
   any x;
   double dx, dy, dz;
   cell c1;

   dx = evDouble(ex, x = cdr(ex)) / SCL;
   dy = evDouble(ex, x = cdr(x)) / SCL;
   dz = evDouble(ex, x = cdr(x)) / SCL;

   if (isCell(x = cdr(x))) {
      dx -= evDouble(ex, x) / SCL;
      dy -= evDouble(ex, x = cdr(x)) / SCL;
      dz -= evDouble(ex, x = cdr(x)) / SCL;
   }

   Push(c1, doubleToNum(atan2(dy,dx) * SCL));
   dx = sqrt(dx*dx + dy*dy + dz*dz);
   data(c1) = cons(data(c1), doubleToNum(dx==0.0? 0.0 : asin(dz/dx)*SCL));
   return Pop(c1);
}

static void rotate(vector *src, matrix *p, vector *dst) {
   dst->x = src->x * p->a.x + src->y * p->b.x + src->z * p->c.x;
   dst->y = src->x * p->a.y + src->y * p->b.y + src->z * p->c.y;
   dst->z = src->x * p->a.z + src->y * p->b.z + src->z * p->c.z;
}

#if 0
/* (lst -- x y z) */
void Locate(void) {
   any lst;
   vector pos, v, w;
   matrix rot, r;

   lst = Tos;
   getMatrix(getVector(car(lst), &pos), &rot);
   while (isCell(lst = cdr(lst))) {
      getMatrix(getVector(car(lst), &v), &r);
      rotate(&v, &rot, &w);
      pos.x += w.x,  pos.y += w.y,  pos.z += w.z;
      v = r.a,  rotate(&v, &rot, &r.a);
      v = r.b,  rotate(&v, &rot, &r.b);
      v = r.c,  rotate(&v, &rot, &r.c);
      rot = r;
   }
   Tos = doubleToNum(pos.x) * SCL;
   push(doubleToNum(pos.y)) * SCL;
   push(doubleToNum(pos.z)) * SCL;
}
#endif

static void shadowPt(double vx, double vy) {
   double z;

   z = Coeff7 * vx + Coeff8 * vy - Pos9;
   prn((int)(FocLen * (Coeff1 * vx + Coeff2 * vy) / z));
   prn((int)(FocLen * (Coeff4 * vx + Coeff5 * vy - Pos6) / z));
   prn(num(1000.0 * z));
}

static void transPt(double vx, double vy, double vz) {
   double x, y, z;
   int h, v, dh, dv, d;

   x = Coeff1 * vx + Coeff2 * vy;
   y = Coeff4 * vx + Coeff5 * vy + Coeff6 * vz;
   z = Coeff7 * vx + Coeff8 * vy + Coeff9 * vz;
   prn(h = (int)(FocLen * x/z));
   prn(v = (int)(FocLen * y/z));
   prn(num(1000.0 * z));
   if (Snap) {
      if ((dh = h - Snap1h) < 0)
         dh = -dh;
      if ((dv = v - Snap1v) < 0)
         dv = -dv;
      if ((d = dh>dv? dh+dv*41/100-dh/24 : dv+dh*41/100-dv/24) < SnapD) {
         SnapD = d;
         Snap2h = h;  Snap2v = v;
         SnapX = vx;  SnapY = vy;  SnapZ = vz;
      }
   }
}

static void doDraw(any ex, any mdl, matrix *r, double x, double y, double z) {
   any face, c1, c2, txt;
   long n, pix;
   double dx, dy, dz;
   vector pos, pt1, pt2, pt3, v, w, nv;
   matrix rot;

   Fetch(ex,mdl);
   mdl = getMatrix(getVector(val(mdl), &pos), &rot);
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

   if ((z = Coeff7*dx + Coeff8*dy + Coeff9*dz) < 0.1)
      return;
   if (z < fabs(Coeff1*dx + Coeff2*dy))
      return;
   if (z < fabs(Coeff4*dx + Coeff5*dy + Coeff6*dz))
      return;

   while (isCell(mdl)) {
      face = car(mdl),  mdl = cdr(mdl);
      if (isSym(face))
         doDraw(ex, face, &rot, pos.x, pos.y, pos.z);
      else {
         c1 = car(face),  face = cdr(face);
         c2 = car(face),  face = cdr(face);
         if (!isSym(car(face)))
            txt = Nil;
         else
            txt = car(face),  face = cdr(face);
         face = getVector(getVector(face, &v), &w);
         if ((v.x || v.y || v.z) && (w.x || w.y || w.z))
            r = &rot,  rotate(&v, r, &pt1),  rotate(&w, r, &pt2);
         else
            rotate(&v, r, &pt1),  rotate(&w, r, &pt2),  r = &rot;
         face = getVector(face, &v),  rotate(&v, r, &pt3);
         if (c2 == T) {
            n = length(face) / 3;
            prn(n+2);
            shadowPt(pt1.x + dx + pt1.z + pos.z, pt1.y + dy);
            pr(0,txt);
            shadowPt(pt2.x + dx + pt2.z + pos.z, pt2.y + dy);
            shadowPt(pt3.x + dx + pt3.z + pos.z, pt3.y + dy);
            while (--n >= 0) {
               face = getVector(face, &v),  rotate(&v, r, &pt1);
               shadowPt(pt1.x + dx + pt1.z + pos.z, pt1.y + dy);
            }
            prn(0);
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
            if (isNil(c1) && isNil(c2))
               pix = -1;  // Transparent
            else {
               if (pt1.x * nv.x + pt1.y * nv.y + pt1.z * nv.z >= 0.0) {
                  if (isNil(c1))
                     continue;  // Backface culling
                  pix = unDig(c1) / 2;
                  n = 80 - num(14.14 * (nv.z-nv.x) / sqrt(nv.x*nv.x + nv.y*nv.y + nv.z*nv.z));
               }
               else {
                  if (isNil(c2))
                     continue;  // Backface culling
                  pix = unDig(c2) / 2;
                  n = 80 + num(14.14 * (nv.z-nv.x) / sqrt(nv.x*nv.x + nv.y*nv.y + nv.z*nv.z));
               }
               pix = ((pix >> 16) & 255) * n / 100 << 16  |
                     ((pix >> 8) & 255) * n / 100 << 8  |  (pix & 255) * n / 100;
            }
            n = length(face) / 3;
            prn(n+2);
            transPt(pt1.x, pt1.y, pt1.z);
            pr(0,txt);
            transPt(pt2.x + dx, pt2.y + dy, pt2.z + dz);
            transPt(pt3.x + dx, pt3.y + dy, pt3.z + dz);
            while (--n >= 0) {
               face = getVector(face, &v),  rotate(&v, r, &pt1);
               transPt(pt1.x + dx, pt1.y + dy, pt1.z + dz);
            }
            prn(pix);
         }
      }
   }
}

// (z3d:Draw 'foc 'yaw 'pitch 'x 'y 'z 'sky 'gnd ['h 'v]) -> NIL
// (z3d:Draw 'sym) -> NIL
// (z3d:Draw 'NIL) -> lst
any Draw(any ex) {
   any x, y;
   double a, sinY, cosY, sinP, cosP;

   x = cdr(ex);
   if (isNil(y = EVAL(car(x)))) {
      cell c1;

      prn(0);
      if (!Snap) {
         prn(32767);
         return Nil;
      }
      prn(Snap2h),  prn(Snap2v);
      Push(c1, doubleToNum(SnapZ * SCL));
      data(c1) = cons(doubleToNum(SnapY * SCL), data(c1));
      data(c1) = cons(doubleToNum(SnapX * SCL), data(c1));
      return Pop(c1);
   }
   if (isSym(y)) {
      doDraw(ex, y, NULL, 0.0, 0.0, 0.0);
      return Nil;
   }
   FocLen = numToDouble(y) / SCL;
   a = evDouble(ex, x = cdr(x)) / SCL,  sinY = sin(a),  cosY = cos(a);
   a = evDouble(ex, x = cdr(x)) / SCL,  sinP = sin(a),  cosP = cos(a);
   PosX = evDouble(ex, x = cdr(x)) / SCL;
   PosY = evDouble(ex, x = cdr(x)) / SCL;
   PosZ = evDouble(ex, x = cdr(x)) / SCL;

   Coeff1 = -sinY;
   Coeff2 = cosY;
   Coeff4 = cosY * sinP;
   Coeff5 = sinY * sinP;
   Coeff6 = -cosP;
   Coeff7 = cosY * cosP;
   Coeff8 = sinY * cosP;
   Coeff9 = sinP;

   Pos6 = Coeff6 * PosZ;
   Pos9 = Coeff9 * PosZ;

   if (cosP == 0.0)
      prn(sinP > 0.0? +16383 : -16384);
   else if ((a = FocLen * sinP/cosP) > +16383.0)
      prn(+16383);
   else if (a < -16384.0)
      prn(-16384);
   else
      prn(num(a));
   prn(evCnt(ex, x = cdr(x)));
   prn(evCnt(ex, x = cdr(x)));
   x = cdr(x);
   if (Snap = !isNil(y = EVAL(car(x)))) {
      SnapD = 32767;
      Snap1h = (int)xCnt(ex,y);
      Snap1v = (int)evCnt(ex,cdr(x));
   }
   return Nil;
}
