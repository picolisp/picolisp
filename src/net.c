/* 11dec02abu
 * (c) Software Lab. Alexander Burger
 */

#include "pico.h"

#include <netdb.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/tcp.h>

static int Peer;

static void tcpErr(any ex, char *s) {
   err(ex, NULL, "TCP %s error: %s", s, sys_errlist[errno]);
}

static int tcpSocket(any ex) {
   int sd;

   if ((sd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
      tcpErr(ex, "socket");
   return sd;
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
   if ((Peer = accept(sd, NULL, 0)) < 0)
      tcpErr(ex, "accept");
   return boxCnt(Peer);
}

// (peer ['cnt]) -> sym
any doPeer(any ex) {
   any x;
   int len;
   struct sockaddr_in addr;
   struct hostent *p;

   len = sizeof(addr);
   if (getpeername(isNil(x = EVAL(cadr(ex)))? Peer : (int)xCnt(ex,x),
                                          (struct sockaddr*)&addr, &len) < 0)
      return Nil;
   if (p = gethostbyaddr((char*)&addr.sin_addr, sizeof(addr.sin_addr), AF_INET))
      return mkStr(p->h_name);
   return mkStr(inet_ntoa(addr.sin_addr));
}

// (connect 'sym 'cnt) -> cnt
any doConnect(any ex) {
   any x, y;
   int sd;
   struct sockaddr_in addr;
   struct hostent *p;

   x = cdr(ex),  y = EVAL(car(x));                             // host
   NeedSym(ex,y);
   {
      char nm[bufSize(y)];

      bufString(y, nm);
      bzero((char*)&addr, sizeof(addr));
      if ((long)(addr.sin_addr.s_addr = inet_addr(nm)) == -1) {
         if (!(p = gethostbyname(nm))  ||  p->h_length == 0)
            return Nil;
         addr.sin_addr.s_addr = ((struct in_addr*)p->h_addr_list[0])->s_addr;
      }
   }
   sd = tcpSocket(ex);
   addr.sin_family = AF_INET;
   addr.sin_port = htons((unsigned short)evCnt(ex, cdr(x)));   // port
   if (connect(sd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
      close(sd);
      return Nil;
   }
   return boxCnt(sd);
}
