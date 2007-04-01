/* 18feb07abu
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

static int ipSocket(any ex, int type) {
   int sd;

   if ((sd = socket(AF_INET, type, 0)) < 0)
      ipErr(ex, "socket");
   return sd;
}

static any tcpAccept(any ex, int sd) {
   int i, sd2;
   struct sockaddr_in addr;
   struct timespec tv = {0,100000000};  // 100 ms

   blocking(NO, ex, sd);
   i = 200; do {
      socklen_t len = sizeof(addr);
      if ((sd2 = accept(sd, (struct sockaddr*)&addr, &len)) >= 0) {
         blocking(YES, ex, sd2);
         val(Adr) = mkStr(inet_ntoa(addr.sin_addr));
         return boxCnt(sd2);
      }
      nanosleep(&tv,NULL);
   } while (errno == EAGAIN  &&  --i >= 0);
   blocking(YES, ex, sd);
   return NULL;
}

// (port ['T] 'cnt|(cnt . cnt) ['var]) -> cnt
any doPort(any ex) {
   any x, y;
   int type, n, sd;
   unsigned short port;
   cell c1;
   struct sockaddr_in addr;

   memset(&addr, 0, sizeof(addr));
   addr.sin_family = AF_INET;
   addr.sin_addr.s_addr = htonl(INADDR_ANY);
   x = cdr(ex);
   type = SOCK_STREAM;
   if ((y = EVAL(car(x))) == T)
      type = SOCK_DGRAM,  x = cdr(x),  y = EVAL(car(x));
   sd = ipSocket(ex, type);
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
   if (!isNil(data(c1) = EVAL(cadr(x)))) {
      socklen_t len = sizeof(addr);
      if (getsockname(sd, (struct sockaddr*)&addr, &len) < 0)
         close(sd),  ipErr(ex, "getsockname");
      Save(c1);
      NeedVar(ex,data(c1));
      CheckVar(ex,data(c1));
      Touch(ex,data(c1));
      val(data(c1)) = boxCnt(ntohs(addr.sin_port));
      drop(c1);
   }
   return boxCnt(sd);
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
      if (x = tcpAccept(ex,sd))
         return x;
   }
}

// (accept 'cnt) -> cnt | NIL
any doAccept(any ex) {
   return tcpAccept(ex, (int)evCnt(ex, cdr(ex))) ?: Nil;
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

   bufString(host, nm);
   memset(addr, 0, sizeof(struct sockaddr_in));
   if (!inet_aton(nm, &addr->sin_addr)) {
      if (!(p = gethostbyname(nm))  ||  p->h_length == 0)
         return NO;
      addr->sin_addr.s_addr = ((struct in_addr*)p->h_addr_list[0])->s_addr;
   }
   addr->sin_port = htons(port);
   addr->sin_family = AF_INET;
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
   sd = ipSocket(ex, SOCK_STREAM);
   if (connect(sd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
      close(sd);
      return Nil;
   }
   return boxCnt(sd);
}

// (nagle 'cnt 'flg) -> cnt
any doNagle(any ex) {
   any x, y;
   int sd, opt;

   x = cdr(ex),  y = EVAL(car(x));
   sd = (int)xCnt(ex,y);
   x = cdr(x),  opt = isNil(EVAL(car(x)))? 1 : 0;
   if (setsockopt(sd, IPPROTO_TCP, TCP_NODELAY, (char*)&opt, sizeof(int)) < 0)
      ipErr(ex, "setsockopt");
   return y;
}

/*** UDP send/receive ***/
#define UDPMAX 4096
static byte *UdpBuf, *UdpPtr;

static void putUdp(int c) {
   *UdpPtr++ = c;
   if (UdpPtr == UdpBuf + UDPMAX)
      err(NULL, NULL, "UDP overflow");
}

static int getUdp(int n __attribute__((unused))) {
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
      return binRead() ?: Nil;
   }
   Save(c1);
   if (!server(xSym(data(c1)), (unsigned short)evCnt(ex,x), &addr))
      x = Nil;
   else {
      x = cdr(x),  x = EVAL(car(x));
      sd = ipSocket(ex, SOCK_DGRAM);
      putBin = putUdp,  UdpPtr = UdpBuf = buf,  binPrint(x);
      sendto(sd, buf, UdpPtr-buf, 0, (struct sockaddr*)&addr, sizeof(struct sockaddr_in));
      close(sd);
   }
   drop(c1);
   return x;
}
