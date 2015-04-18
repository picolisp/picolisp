/* 30jan15abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

static void ipErr(any ex, char *s) {
   err(ex, NULL, "IP %s error: %s", s, strerror(errno));
}

// (port ['T] 'cnt|(cnt . cnt) ['var]) -> cnt
any doPort(any ex) {
   any x, y;
   int type, sd, n;
   unsigned short port;
   struct sockaddr_in6 addr;

   x = cdr(ex);
   type = SOCK_STREAM;
   if ((y = EVAL(car(x))) == T)
      type = SOCK_DGRAM,  x = cdr(x),  y = EVAL(car(x));
   if ((sd = socket(AF_INET6, type, 0)) < 0)
      ipErr(ex, "socket");
   closeOnExec(ex, sd);
   n = 0;
#ifndef __OpenBSD__
   if (setsockopt(sd, IPPROTO_IPV6, IPV6_V6ONLY, &n, sizeof(n)) < 0)
      ipErr(ex, "IPV6_V6ONLY");
#endif
   memset(&addr, 0, sizeof(addr));
   addr.sin6_family = AF_INET6;
   addr.sin6_addr = in6addr_any;
   if (isNum(y)) {
      if ((port = (unsigned short)xCnt(ex,y)) != 0) {
         n = 1;
         if (setsockopt(sd, SOL_SOCKET, SO_REUSEADDR, &n, sizeof(n)) < 0)
            ipErr(ex, "SO_REUSEADDR");
      }
   }
   else if (isCell(y))
      port = (unsigned short)xCnt(ex,car(y));
   else
      argError(ex,y);
   for (;;) {
      addr.sin6_port = htons(port);
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
      val(y) = boxCnt(ntohs(addr.sin6_port));
   }
   return boxCnt(sd);
}

static any tcpAccept(int sd) {
   int i, f, sd2;
   char s[INET6_ADDRSTRLEN];
   struct sockaddr_in6 addr;

   f = nonblocking(sd);
   i = 200; do {  // 20 s
      socklen_t len = sizeof(addr);
      if ((sd2 = accept(sd, (struct sockaddr*)&addr, &len)) >= 0) {
         fcntl(sd, F_SETFL, f);
#ifndef __linux__
         fcntl(sd2, F_SETFL, 0);
#endif
         inet_ntop(AF_INET6, &addr.sin6_addr, s, INET6_ADDRSTRLEN);
         val(Adr) = mkStr(s);
         initInFile(sd2,NULL), initOutFile(sd2);
         return boxCnt(sd2);
      }
      usleep(100000);  // 100 ms
   } while (errno == EAGAIN  &&  --i);
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
   x = evSym(cdr(x));
   {
      struct addrinfo *lst, *p;
      char host[NI_MAXHOST];
      char nm[bufSize(x)];

      bufString(x, nm);
      if (getaddrinfo(nm, NULL, NULL, &lst))
         return Nil;
      x = Nil;
      for (p = lst; p; p = p->ai_next) {
         if (getnameinfo(p->ai_addr, p->ai_addrlen, host, NI_MAXHOST, NULL, 0, NI_NAMEREQD) == 0 && host[0]) {
            x = mkStr(host);
            break;
         }
      }
      freeaddrinfo(lst);
      return x;
   }
}

static struct addrinfo *server(int type, any node, any service) {
   struct addrinfo hints, *lst;
   char nd[bufSize(node)], sv[bufSize(service)];

   memset(&hints, 0, sizeof(hints));
   hints.ai_family = AF_UNSPEC;
   hints.ai_socktype = type;
   bufString(node, nd),  bufString(service, sv);
   return getaddrinfo(nd, sv, &hints, &lst)? NULL : lst;
}

// (connect 'any1 'any2) -> cnt | NIL
any doConnect(any ex) {
   struct addrinfo *lst, *p;
   any port;
   int sd;
   cell c1;

   Push(c1, evSym(cdr(ex)));
   port = evSym(cddr(ex));
   if (lst = server(SOCK_STREAM, Pop(c1), port)) {
      for (p = lst; p; p = p->ai_next) {
         if ((sd = socket(p->ai_family, p->ai_socktype, 0)) >= 0) {
            if (connect(sd, p->ai_addr, p->ai_addrlen) == 0) {
               closeOnExec(ex, sd);
               initInFile(sd,NULL), initOutFile(sd);
               freeaddrinfo(lst);
               return boxCnt(sd);
            }
            close(sd);
         }
      }
      freeaddrinfo(lst);
   }
   return Nil;
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

// (udp 'any1 'any2 'any3) -> any
// (udp 'cnt) -> any
any doUdp(any ex) {
   any x, y;
   cell c1;
   struct addrinfo *lst, *p;
   int sd;
   byte buf[UDPMAX];

   x = cdr(ex),  data(c1) = EVAL(car(x));
   if (!isCell(x = cdr(x))) {
      if (recv((int)xCnt(ex, data(c1)), buf, UDPMAX, 0) < 0)
         return Nil;
      getBin = getUdp,  UdpPtr = UdpBuf = buf;
      return binRead(ExtN) ?: Nil;
   }
   Save(c1);
   data(c1) = xSym(data(c1));
   y = evSym(x);
   drop(c1);
   if (lst = server(SOCK_DGRAM, data(c1), y)) {
      x = cdr(x),  x = EVAL(car(x));
      putBin = putUdp,  UdpPtr = UdpBuf = buf,  binPrint(ExtN, x);
      for (p = lst; p; p = p->ai_next) {
         if ((sd = socket(p->ai_family, p->ai_socktype, 0)) >= 0) {
            sendto(sd, buf, UdpPtr-buf, 0, p->ai_addr, p->ai_addrlen);
            close(sd);
            freeaddrinfo(lst);
            return x;
         }
      }
      freeaddrinfo(lst);
   }
   return Nil;
}
