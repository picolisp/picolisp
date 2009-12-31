/* 08oct09abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

#include <netdb.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/tcp.h>
#include <netinet/in.h>

static void ipErr(any ex, char *s) {
   err(ex, NULL, "IP %s error: %s", s, strerror(errno));
}

// (port ['T] 'cnt|(cnt . cnt) ['var]) -> cnt
any doPort(any ex) {
   any x, y;
   int type, n, sd;
   unsigned short port;
   struct sockaddr_in addr;

   x = cdr(ex);
   type = SOCK_STREAM;
   if ((y = EVAL(car(x))) == T)
      type = SOCK_DGRAM,  x = cdr(x),  y = EVAL(car(x));
   if ((sd = socket(AF_INET, type, 0)) < 0)
      ipErr(ex, "socket");
   closeOnExec(ex, sd);
   memset(&addr, 0, sizeof(addr));
   addr.sin_family = AF_INET;
   addr.sin_addr.s_addr = htonl(INADDR_ANY);
   if (isNum(y)) {
      if ((port = (unsigned short)xCnt(ex,y)) != 0) {
         n = 1;
         if (setsockopt(sd, SOL_SOCKET, SO_REUSEADDR, &n, sizeof(n)) < 0)
            ipErr(ex, "setsockopt");
      }
   }
   else if (isCell(y))
      port = (unsigned short)xCnt(ex,car(y));
   else
      argError(ex,y);
   for (;;) {
      addr.sin_port = htons(port);
      if (bind(sd, (struct sockaddr*)&addr, sizeof(addr)) >= 0)
         break;
      if (!isCell(y)  ||  ++port > xCnt(ex,cdr(y)))
         close(sd),  ipErr(ex, "bind");
   }
   if (type == SOCK_STREAM  &&  listen(sd,5) < 0)
      close(sd),  ipErr(ex, "listen");
   if (!isNil(y = EVAL(cadr(x)))) {
      socklen_t len = sizeof(addr);
      if (getsockname(sd, (struct sockaddr*)&addr, &len) < 0)
         close(sd),  ipErr(ex, "getsockname");
      NeedVar(ex,y);
      CheckVar(ex,y);
      val(y) = boxCnt(ntohs(addr.sin_port));
   }
   return boxCnt(sd);
}

static any tcpAccept(int sd) {
   int i, f, sd2;
   struct sockaddr_in addr;

   f = nonblocking(sd);
   i = 200; do {
      socklen_t len = sizeof(addr);
      if ((sd2 = accept(sd, (struct sockaddr*)&addr, &len)) >= 0) {
         fcntl(sd, F_SETFL, f);
         val(Adr) = mkStr(inet_ntoa(addr.sin_addr));
         initInFile(sd2,NULL), initOutFile(sd2);
         return boxCnt(sd2);
      }
      usleep(100000);  // 100 ms
   } while (errno == EAGAIN  &&  --i >= 0);
   fcntl(sd, F_SETFL, f);
   return NULL;
}

// (accept 'cnt) -> cnt | NIL
any doAccept(any ex) {
   return tcpAccept((int)evCnt(ex, cdr(ex))) ?: Nil;
}

// (listen 'cnt1 ['cnt2]) -> cnt | NIL
any doListen(any ex) {
   any x;
   int sd;
   long ms;

   sd = (int)evCnt(ex, x = cdr(ex));
   x = cdr(x);
   ms = isNil(x = EVAL(car(x)))? -1 : xCnt(ex,x);
   for (;;) {
      if (!waitFd(ex, sd, ms))
         return Nil;
      if (x = tcpAccept(sd))
         return x;
   }
}

// (host 'any) -> sym
any doHost(any x) {
   struct in_addr in;
   struct hostent *p;

   x = evSym(cdr(x));
   {
      char nm[bufSize(x)];

      bufString(x, nm);
      if (inet_aton(nm, &in) && (p = gethostbyaddr((char*)&in, sizeof(in), AF_INET)))
         return mkStr(p->h_name);
      return Nil;
   }
}

static bool server(any host, unsigned short port, struct sockaddr_in *addr) {
   struct hostent *p;
   char nm[bufSize(host)];

   memset(addr, 0, sizeof(struct sockaddr_in));
   addr->sin_port = htons(port);
   addr->sin_family = AF_INET;
   bufString(host, nm);
   if (!inet_aton(nm, &addr->sin_addr)) {
      if (!(p = gethostbyname(nm))  ||  p->h_length == 0)
         return NO;
      addr->sin_addr.s_addr = ((struct in_addr*)p->h_addr_list[0])->s_addr;
   }
   return YES;
}

// (connect 'any 'cnt) -> cnt | NIL
any doConnect(any ex) {
   int sd, port;
   cell c1;
   struct sockaddr_in addr;

   Push(c1, evSym(cdr(ex)));
   port = evCnt(ex, cddr(ex));
   if (!server(Pop(c1), (unsigned short)port, &addr))
      return Nil;
   if ((sd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
      ipErr(ex, "socket");
   closeOnExec(ex, sd);
   if (connect(sd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
      close(sd);
      return Nil;
   }
   initInFile(sd,NULL), initOutFile(sd);
   return boxCnt(sd);
}

/*** UDP send/receive ***/
#define UDPMAX 4096
static byte *UdpBuf, *UdpPtr;

static void putUdp(int c) {
   if (UdpPtr == UdpBuf + UDPMAX)
      err(NULL, NULL, "UDP overflow");
   *UdpPtr++ = c;
}

static int getUdp(void) {
   if (UdpPtr == UdpBuf + UDPMAX)
      return -1;
   return *UdpPtr++;
}

// (udp 'any1 'cnt 'any2) -> any
// (udp 'cnt) -> any
any doUdp(any ex) {
   any x;
   int sd;
   cell c1;
   struct sockaddr_in addr;
   byte buf[UDPMAX];

   x = cdr(ex),  data(c1) = EVAL(car(x));
   if (!isCell(x = cdr(x))) {
      if (recv((int)xCnt(ex, data(c1)), buf, UDPMAX, 0) < 0)
         return Nil;
      getBin = getUdp,  UdpPtr = UdpBuf = buf;
      return binRead(ExtN) ?: Nil;
   }
   Save(c1);
   if (!server(xSym(data(c1)), (unsigned short)evCnt(ex,x), &addr))
      x = Nil;
   else {
      x = cdr(x),  x = EVAL(car(x));
      putBin = putUdp,  UdpPtr = UdpBuf = buf,  binPrint(ExtN, x);
      if ((sd = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
         ipErr(ex, "socket");
      sendto(sd, buf, UdpPtr-buf, 0, (struct sockaddr*)&addr, sizeof(struct sockaddr_in));
      close(sd);
   }
   drop(c1);
   return x;
}
