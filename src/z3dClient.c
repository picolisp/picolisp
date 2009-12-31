/* 12nov09abu
 * (c) Software Lab. Alexander Burger
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <sys/shm.h>
#include <X11/extensions/XShm.h>


typedef unsigned char byte;
typedef struct {long h[2]; unsigned long z[2];} edge;

/* Globals */
static int Socket;
static Display *Disp;
static int Scrn;
static int Dpth;
static int PixSize;
static Colormap Cmap;
static GC Gc;
static Window Win;
static long long Tim;

/* 3D-Environment */
static int SizX, SizY, OrgX, OrgY, SnapX, SnapY;
static unsigned long *Zbuff;
static edge *Edges;
static XImage *Img;
static XShmSegmentInfo Info;


/* Error exit */
static void giveup(char *msg) {
   fprintf(stderr, "z3dClient: %s\r\n", msg);
   exit(1);
}

/* Memory allocation */
void *alloc(long siz) {
   void *p;

   if (!(p = malloc(siz)))
      giveup("No memory");
   return p;
}

static void paint(void) {
   XEvent ev;

   while (XCheckTypedEvent(Disp, Expose, &ev));
   XShmPutImage(Disp, Win, Gc, Img, 0, 0, 0, 0, SizX, SizY, False);
   if (SnapX != 32767) {
      XSetFunction(Disp, Gc, GXinvert);
      XFillRectangle(Disp, Win, Gc, OrgX+SnapX-3, OrgY+SnapY-3, 6, 6);
      XSetFunction(Disp, Gc, GXcopy);
   }
   XSync(Disp,False);
}

static void prLong(long n) {
   int i;
   char buf[8];

   n = n >= 0? n * 2 : -n * 2 + 1;
   if ((n & 0xFFFFFF00) == 0)
      i = 2, buf[0] = 1*4, buf[1] = n;
   else if ((n & 0xFFFF0000) == 0)
      i = 3, buf[0] = 2*4, buf[1] = n, buf[2] = n>>8;
   else if ((n & 0xFF000000) == 0)
      i = 4, buf[0] = 3*4, buf[1] = n, buf[2] = n>>8, buf[3] = n>>16;
   else
      i = 5, buf[0] = 4*4, buf[1] = n, buf[2] = n>>8, buf[3] = n>>16, buf[4] = n>>24;
   if (write(Socket, buf, i) <= 0)
      giveup("Socket write error");
}


static byte get1(void) {
   static int n, cnt;
   static byte buf[1024];

   while (n == cnt) {
      int fd;
      fd_set fdSet;

      fd = ConnectionNumber(Disp);
      FD_ZERO(&fdSet);
      FD_SET(fd, &fdSet);
      FD_SET(Socket, &fdSet);
      while (select((fd > Socket? fd : Socket) + 1, &fdSet, NULL,NULL,NULL) < 0)
         if (errno != EINTR)
            giveup("Select error");
      if (FD_ISSET(fd, &fdSet)) {
         XEvent ev;

         XNextEvent(Disp, &ev);
         switch (ev.type) {
         case Expose:
            paint();
            break;
         case KeyPress:
            if (((XKeyEvent*)&ev)->state == 37)  // Ctrl-Key
               printf("Ok\n");  //#?
            break;
         case KeyRelease:
            break;
         case ButtonPress:
            prLong('c');  // clk
            prLong(((XButtonEvent*)&ev)->x - OrgX);
            prLong(((XButtonEvent*)&ev)->y - OrgY);
            break;
         case MotionNotify:  //#?
            break;
         }
      }
      if (FD_ISSET(Socket, &fdSet)) {
         while ((cnt = read(Socket, buf, sizeof(buf))) < 0)
            if (errno != EINTR)
               giveup("Socket read error");
         if (cnt == 0)
            exit(0);
         n = 0;
      }
   }
   return buf[n++];
}

static long getNum(void) {
   int cnt = get1() / 4;
   long n = get1();
   int i = 0;

   while (--cnt)
      n |= get1() << (i += 8);
   if (n & 1)
      n = -n;
   return n / 2;
}

static void skipStr(void) {
   int cnt = get1() / 4;
   while (--cnt >= 0)
      get1();
}

static long getColor(long c) {
   XColor col;

   col.red   = c >> 8  &  0xFF00;
   col.green = c & 0xFF00;
   col.blue  = (c & 0xFF) << 8;
   col.flags = DoRed | DoGreen | DoBlue;
   if (!XAllocColor(Disp, Cmap, &col))
      giveup("Can't allocate color");
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

static void zDots(long i, long h, long h2, unsigned long z, unsigned long z2) {
   char *frame;
   unsigned long *zbuff;

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
         *zbuff = z,  *(long*)frame = (long)0;
      if (z2 < *(zbuff += i))
         *zbuff = z2,  *(long*)(frame + 4 * i) = (long)0;
      break;
   }
}

static void zLine(long pix, long v, long h, long h2,
                                       unsigned long z, unsigned long z2) {
   char *frame;
   unsigned long *zbuff;
   long d, e, dh, dz, sz;

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
               *zbuff = z,  *(long*)frame = pix;
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

/*** Main entry point ***/
int main(int ac, char *av[]) {
   struct sockaddr_in addr;
   struct hostent *hp;
   XPixmapFormatValues *pmFormat;
   long hor, sky, gnd, pix, v;
   int n, i, x0, y0, z0, x1, y1, z1, x2, y2, z2;
   char *frame;
   edge *e;
   long long t;
   struct timeval tv;

   if (ac != 3)
      giveup("Use: <host> <port>");

   /* Open Connection */
   memset(&addr, 0, sizeof(addr));
   if ((long)(addr.sin_addr.s_addr = inet_addr(av[1])) == -1) {
      if (!(hp = gethostbyname(av[1]))  ||  hp->h_length == 0)
         giveup("Can't get host");
      addr.sin_addr.s_addr = ((struct in_addr*)hp->h_addr_list[0])->s_addr;
   }
   if ((Socket = socket(AF_INET, SOCK_STREAM, 0)) < 0)
      giveup("Can't create socket");
   addr.sin_family = AF_INET;
   addr.sin_port = htons(atol(av[2]));
   if (connect(Socket, (struct sockaddr*)&addr, sizeof(addr)) < 0)
      giveup("Can't connect");

   /* Open Display */
   if ((Disp = XOpenDisplay(NULL)) == NULL)
      giveup("Can't open Display");
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
      giveup("Bad Display Depth");
   Gc = XCreateGC(Disp,RootWindow(Disp,Scrn), 0, NULL);

   OrgX = (SizX = getNum()) / 2;
   OrgY = (SizY = getNum()) / 2;

   /* Create Window */
   Win = XCreateSimpleWindow(Disp, RootWindow(Disp,Scrn), 0, 0, SizX, SizY,
                        1, BlackPixel(Disp,Scrn), WhitePixel(Disp,Scrn) );
   XStoreName(Disp, Win, "PicoLisp z3d");
   XSelectInput(Disp, Win,
      ExposureMask |
      KeyPressMask | KeyReleaseMask |
      ButtonPressMask |
      PointerMotionMask );
   XMapWindow(Disp, Win);

   /* Create Image */
   SizX = SizX + 3 & ~3;
   SizY = SizY + 3 & ~3;
   Zbuff = alloc(SizX * SizY * sizeof(unsigned long));
   Edges = alloc(SizY * sizeof(edge));
   if (!XShmQueryExtension(Disp)  ||
         !(Img = XShmCreateImage(Disp, DefaultVisual(Disp, Scrn),
                  Dpth, ZPixmap, NULL, &Info, SizX, SizY ))  ||
         (Info.shmid = shmget(IPC_PRIVATE,
                  SizX * SizY * PixSize, IPC_CREAT | 0777 )) < 0  ||
         (Info.shmaddr = Img->data =
                           shmat(Info.shmid, 0, 0) ) == (char*)-1  ||
         !XShmAttach(Disp, &Info) )
      giveup("Can't create XImage");

   /* Main loop */
   for (;;) {
      prLong('o');  // ok
      hor = getNum() + OrgY;
      sky = getColor(getNum());
      gnd = getColor(getNum());
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
               *(long*)frame = pix,  frame += 4;
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
               *(long*)frame = pix,  frame += 4;
            while (++i < SizX);
            break;
         }
      }
      memset(Zbuff, 0xFF, SizX * SizY * sizeof(unsigned long));

      while (n = getNum()) {
         memset(Edges, 0, SizY * sizeof(edge));
         x0 = x1 = getNum();
         y0 = y1 = getNum();
         z0 = z1 = getNum();
         skipStr();
         for (;;) {
            x2 = getNum();
            y2 = getNum();
            z2 = getNum();
            mkEdge(x1, y1, z1, x2, y2, z2);
            if (--n == 0)
               break;
            x1 = x2,  y1 = y2,  z1 = z2;
         }
         mkEdge(x2, y2, z2, x0, y0, z0);
         i = 0,  e = Edges;
         if ((pix = getNum()) < 0) {
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
      if ((SnapX = getNum()) != 32767)
         SnapY = getNum();
      paint();
      gettimeofday(&tv,NULL),  t = tv.tv_sec * 1000LL + tv.tv_usec / 1000;
      if (Tim > t) {
         tv.tv_sec = 0,  tv.tv_usec = (Tim - t) * 1000;
         select(0, NULL, NULL, NULL, &tv);
         t = Tim;
      }
      Tim = t + 40;
   }
}
