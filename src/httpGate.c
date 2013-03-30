/* 04feb13abu
 * (c) Software Lab. Alexander Burger
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <ctype.h>
#include <string.h>
#include <signal.h>
#include <time.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>

#include <openssl/pem.h>
#include <openssl/ssl.h>
#include <openssl/err.h>

typedef enum {NO,YES} bool;

static int Http1;

static char Head_410[] =
   "HTTP/1.0 410 Gone\r\n"
   "Server: PicoLisp\r\n"
   "Content-Type: text/html; charset=utf-8\r\n"
   "\r\n";

static void giveup(char *msg) {
   fprintf(stderr, "httpGate: %s\n", msg);
   exit(2);
}

static inline bool pre(char *p, char *s) {
   while (*s)
      if (*p++ != *s++)
         return NO;
   return YES;
}

static int slow(SSL *ssl, int fd, char *p, int cnt) {
   int n;

   while ((n = ssl? SSL_read(ssl, p, cnt) : read(fd, p, cnt)) < 0)
      if (errno != EINTR)
         return 0;
   return n;
}

static int rdLine(SSL *ssl, int fd, char *p, int cnt) {
   int n, len;

   for (len = 0;;) {
      if ((n = ssl? SSL_read(ssl, p, cnt) : read(fd, p, cnt)) <= 0) {
         if (!n || errno != EINTR)
            return 0;
      }
      else {
         len += n;
         if (memchr(p, '\n', n))
            return len;
         p += n;
         if ((cnt -= n) == 0)
            return 0;
      }
   }
}

static void wrBytes(int fd, char *p, int cnt) {
   int n;

   do
      if ((n = write(fd, p, cnt)) >= 0)
         p += n, cnt -= n;
      else if (errno != EINTR)
         exit(1);
   while (cnt);
}

static void sslWrite(SSL *ssl, void *p, int cnt) {
   if (SSL_write(ssl, p, cnt) <= 0)
      exit(1);
}

static int gatePort(unsigned short port) {
   int sd, n;
   struct sockaddr_in6 addr;

   if ((sd = socket(AF_INET6, SOCK_STREAM, 0)) < 0)
      exit(1);
   n = 0;
   if (setsockopt(sd, IPPROTO_IPV6, IPV6_V6ONLY, &n, sizeof(n)) < 0)
      exit(1);
   memset(&addr, 0, sizeof(addr));
   addr.sin6_family = AF_INET6;
   addr.sin6_addr = in6addr_any;
   n = 1;
   if (setsockopt(sd, SOL_SOCKET, SO_REUSEADDR, &n, sizeof(n)) < 0)
      exit(1);
   addr.sin6_port = htons(port);
   if (bind(sd, (struct sockaddr*)&addr, sizeof(addr)) < 0)
      exit(1);
   if (listen(sd,5) < 0)
      exit(1);
   return sd;
}

static int gateConnect(unsigned short port) {
   int sd;
   struct sockaddr_in6 addr;

   if ((sd = socket(AF_INET6, SOCK_STREAM, 0)) < 0)
      exit(1);
   memset(&addr, 0, sizeof(addr));
   addr.sin6_family = AF_INET6;
   addr.sin6_addr = in6addr_loopback;
   addr.sin6_port = htons(port);
   return connect(sd, (struct sockaddr*)&addr, sizeof(addr)) < 0? -1 : sd;
}


static pid_t Buddy;

static void doSigAlarm(int n __attribute__((unused))) {
   kill(Buddy, SIGTERM);
   exit(0);
}

static void doSigUsr1(int n __attribute__((unused))) {
   alarm(420);
}

int main(int ac, char *av[]) {
   int cnt = ac>4? ac-3 : 1, ports[cnt], n, sd, cli, srv;
   struct sockaddr_in6 addr;
   char s[INET6_ADDRSTRLEN];
   char *gate;
   SSL_CTX *ctx;
   SSL *ssl;

   if (ac < 3)
      giveup("port dflt [pem [alt ..]]");

   sd = gatePort(atoi(av[1]));  // e.g. 80 or 443
   ports[0] = atoi(av[2]);  // e.g. 8080
   if (ac == 3 || *av[3] == '\0')
      ssl = NULL,  gate = "X-Pil: *Gate=http\r\nX-Pil: *Adr=%s\r\n";
   else {
      SSL_library_init();
      SSL_load_error_strings();
      if (!(ctx = SSL_CTX_new(SSLv23_server_method())) ||
            !SSL_CTX_use_certificate_file(ctx, av[3], SSL_FILETYPE_PEM) ||
               !SSL_CTX_use_PrivateKey_file(ctx, av[3], SSL_FILETYPE_PEM) ||
                                          !SSL_CTX_check_private_key(ctx) ) {
         ERR_print_errors_fp(stderr);
         giveup("SSL init");
      }
      ssl = SSL_new(ctx),  gate = "X-Pil: *Gate=https\r\nX-Pil: *Adr=%s\r\n";
   }
   for (n = 1; n < cnt; ++n)
      ports[n] = atoi(av[n+3]);

   signal(SIGCHLD,SIG_IGN);  /* Prevent zombies */
   if ((n = fork()) < 0)
      giveup("detach");
   if (n)
      return 0;
   setsid();

   for (;;) {
      socklen_t len = sizeof(addr);
      if ((cli = accept(sd, (struct sockaddr*)&addr, &len)) >= 0 && (n = fork()) >= 0) {
         if (!n) {
            int fd, port, i;
            char *p, *q, buf[4096], buf2[64];

            close(sd);

            alarm(420);
            if (ssl) {
               SSL_set_fd(ssl, cli);
               if (SSL_accept(ssl) < 0)
                  return 1;
            }
            n = rdLine(ssl, cli, buf, sizeof(buf));
            alarm(0);
            if (n < 6)
               return 1;

            /* "GET /url HTTP/1.x"
             * "GET /8080/url HTTP/1.x"
             * "POST /url HTTP/1.x"
             * "POST /8080/url HTTP/1.x"
             */
            if (pre(buf, "GET /"))
               p = buf + 5;
            else if (pre(buf, "POST /"))
               p = buf + 6;
            else
               return 1;

            port = (int)strtol(p, &q, 10);
            if (q == p  ||  *q != ' ' && *q != '/')
               port = ports[0],  q = p;
            else if (port < cnt) {
               if ((port = ports[port]) < 0)
                  return 1;
            }
            else if (port < 1024)
               return 1;
            else
               for (i = 1; i < cnt; ++i)
                  if (port == -ports[i])
                     return 1;

            if ((srv = gateConnect((unsigned short)port)) < 0) {
               if (!memchr(q,'~', buf + n - q))
                  return 1;
               if ((fd = open("void", O_RDONLY)) < 0)
                  return 1;
               alarm(420);
               if (ssl)
                  sslWrite(ssl, Head_410, strlen(Head_410));
               else
                  wrBytes(cli, Head_410, strlen(Head_410));
               alarm(0);
               while ((n = read(fd, buf, sizeof(buf))) > 0) {
                  alarm(420);
                  if (ssl)
                     sslWrite(ssl, buf, n);
                  else
                     wrBytes(cli, buf, n);
                  alarm(0);
               }
               return 0;
            }

            Http1 = 0;
            wrBytes(srv, buf, p - buf);
            if (*q == '/')
               ++q;
            p = q;
            while (*p++ != '\n')
               if (p >= buf + n)
                  return 1;
            wrBytes(srv, q, p - q);
            if (pre(p-10, "HTTP/1."))
               Http1 = *(p-3) - '0';
            inet_ntop(AF_INET6, &addr.sin6_addr, s, INET6_ADDRSTRLEN);
            wrBytes(srv, buf2, sprintf(buf2, gate, s));
            wrBytes(srv, p, buf + n - p);

            signal(SIGALRM, doSigAlarm);
            signal(SIGUSR1, doSigUsr1);
            if (Buddy = fork()) {
               for (;;) {
                  alarm(420);
                  n = slow(ssl, cli, buf, sizeof(buf));
                  alarm(0);
                  if (!n)
                     break;
                  wrBytes(srv, buf, n);
               }
               shutdown(cli, SHUT_RD);
               shutdown(srv, SHUT_WR);
            }
            else {
               Buddy = getppid();
               while ((n = read(srv, buf, sizeof(buf))) > 0) {
                  kill(Buddy, SIGUSR1);
                  alarm(420);
                  if (ssl)
                     sslWrite(ssl, buf, n);
                  else
                     wrBytes(cli, buf, n);
                  alarm(0);
               }
               shutdown(srv, SHUT_RD);
               shutdown(cli, SHUT_WR);
            }
            return 0;
         }
         close(cli);
      }
   }
}
