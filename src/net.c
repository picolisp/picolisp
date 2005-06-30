/* 08apr05abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

#include <netdb.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/tcp.h>

static void tcpErr(any ex, char *s) {
   err(ex, NULL, "TCP %s error: %s", s, strerror(errno));
}

static int tcpSocket(any ex) {
   int sd;

   if ((sd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
      tcpErr(ex, "socket");
   return sd;
}

static any tcpAccept(any ex, int sd) {
   int n, i, sd2;
   struct sockaddr_in addr;
   struct timespec tv = {0,100000000};  // 100 ms

   if ((n = fcntl(sd, F_GETFL, 0)) < 0)
      tcpErr(ex, "GETFL");
   n |= O_NONBLOCK;
   if (fcntl(sd, F_SETFL, n) < 0)
      tcpErr(ex, "SETFL");
   i = 60; do {
      n = sizeof(addr);
      if ((sd2 = accept(sd, (struct sockaddr*)&addr, &n)) >= 0) {
         val(Adr) = mkStr(inet_ntoa(addr.sin_addr));
         return boxCnt(sd2);
      }
      nanosleep(&tv,NULL);
   } while (errno == EAGAIN  &&  --i >= 0);
   return NULL;
}

// (port 'cnt|lst ['var]) -> cnt
any doPort(any ex) {
   any x;
   int n, sd;
   unsigned short port;
   cell c1;
   struct sockaddr_in addr;

   bzero((char*)&addr, sizeof(addr));
   addr.sin_family = AF_INET;
   addr.sin_addr.s_addr = htonl(INADDR_ANY);
   sd = tcpSocket(ex);
   if (isNum(x = EVAL(cadr(ex)))) {
      if ((port = (unsigned short)xCnt(ex,x)) != 0)
         n = 1,  setsockopt(sd, SOL_SOCKET, SO_REUSEADDR, &n, sizeof(n));
   }
   else if (isCell(x))
      port = (unsigned short)xCnt(ex,car(x));
   else
      argError(ex,x);
   for (;;) {
      addr.sin_port = htons(port);
      if (bind(sd, (struct sockaddr*)&addr, sizeof(addr)) >= 0)
         break;
      if (!isCell(x)  ||  ++port > xCnt(ex,cdr(x)))
         close(sd),  tcpErr(ex, "bind");
   }
   if (listen(sd,5) < 0)
      close(sd),  tcpErr(ex, "listen");
   if (!isNil(data(c1) = EVAL(caddr(ex)))) {
      n = sizeof(addr);
      if (getsockname(sd, (struct sockaddr*)&addr, &n) < 0)
         close(sd),  tcpErr(ex, "getsockname");
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

   sd = (int)evCnt(ex, cdr(ex));
   x = cddr(ex);
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
      byte nm[bufSize(x)];

      bufString(x, nm);
      if (inet_aton(nm, &in) && (p = gethostbyaddr((char*)&in, sizeof(in), AF_INET)))
         return mkStr(p->h_name);
      return Nil;
   }
}

// (connect 'any 'cnt) -> cnt | NIL
any doConnect(any ex) {
   any x;
   int sd;
   struct sockaddr_in addr;
   struct hostent *p;

   x = evSym(cdr(ex));
   {
      byte nm[bufSize(x)];

      bufString(x, nm);
      bzero((char*)&addr, sizeof(addr));
      if (!inet_aton(nm, &addr.sin_addr)) {
         if (!(p = gethostbyname(nm))  ||  p->h_length == 0)
            return Nil;
         addr.sin_addr.s_addr = ((struct in_addr*)p->h_addr_list[0])->s_addr;
      }
   }
   sd = tcpSocket(ex);
   addr.sin_family = AF_INET;
   addr.sin_port = htons((unsigned short)evCnt(ex, cddr(ex)));   // port
   if (connect(sd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
      close(sd);
      return Nil;
   }
   return boxCnt(sd);
}
