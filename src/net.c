/* 04nov03abu
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
   int n;
   struct sockaddr_in addr;

   n = sizeof(addr);
   if ((sd = accept(sd, (struct sockaddr*)&addr, &n)) < 0)
      tcpErr(ex, "accept");
   val(Adr) = mkStr(inet_ntoa(addr.sin_addr));
   return boxCnt(sd);
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
   n = 1,  setsockopt(sd = tcpSocket(ex), SOL_SOCKET, SO_REUSEADDR, &n, sizeof(n));
   if (isNum(x = EVAL(cadr(ex))))
      port = (unsigned short)xCnt(ex,x);
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

   sd = (int)evCnt(ex, cdr(ex));
   x = cddr(ex);
   if (!waitFd(ex, sd, isNil(x = EVAL(car(x)))? -1 : xCnt(ex,x)))
      return Nil;
   return tcpAccept(ex,sd);
}

// (accept 'cnt) -> cnt
any doAccept(any ex) {
   return tcpAccept(ex, (int)evCnt(ex, cdr(ex)));
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

// (connect 'any 'cnt) -> cnt
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
