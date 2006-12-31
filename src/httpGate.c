/* 25dec06abu
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
#include <netdb.h>
#include <time.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/tcp.h>
#include <netinet/in.h>

#include <openssl/pem.h>
#include <openssl/ssl.h>
#include <openssl/err.h>

typedef enum {NO,YES} bool;

static char Head_200[] =
   "HTTP/1.0 200 OK\r\n"
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

static int gateSocket(void) {
   int sd;

   if ((sd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
      exit(1);
   return sd;
}

static int gatePort(int port) {
   int n, sd;
   struct sockaddr_in addr;

   memset(&addr, 0, sizeof(addr));
   addr.sin_family = AF_INET;
   addr.sin_addr.s_addr = htonl(INADDR_ANY);
   addr.sin_port = htons((unsigned short)port);
   n = 1,  setsockopt(sd = gateSocket(), SOL_SOCKET, SO_REUSEADDR, &n, sizeof(n));
   if (bind(sd, (struct sockaddr*)&addr, sizeof(addr)) < 0)
      exit(1);
   if (listen(sd,5) < 0)
      exit(1);
   return sd;
}

static int gateConnect(unsigned short port) {
   int sd;
   struct sockaddr_in addr;

   memset(&addr, 0, sizeof(addr));
   addr.sin_addr.s_addr = inet_addr("127.0.0.1");
   sd = gateSocket();
   addr.sin_family = AF_INET;
   addr.sin_port = htons(port);
   return connect(sd, (struct sockaddr*)&addr, sizeof(addr)) < 0? -1 : sd;
}


static pid_t Buddy;

static void doSigAlarm(int n __attribute__((unused))) {
   kill(Buddy, SIGTERM);
   exit(0);
}

int main(int ac, char *av[]) {
   int cnt = ac>4? ac-3 : 1, ports[cnt], n, sd, cli, srv;
   struct sockaddr_in addr;
   char *gate;
   SSL_CTX *ctx;
   SSL *ssl;

   if (ac < 3)
      giveup("port dflt [pem [alt ..]]");

   sd = gatePort(atoi(av[1]));  // e.g. 80 or 443
   ports[0] = atoi(av[2]);  // e.g. 8080
   if (ac == 3 || *av[3] == '\0')
      ssl = NULL,  gate = "Gate: http %s\r\n";
   else {
      SSL_load_error_strings();
      OpenSSL_add_ssl_algorithms();
      if (!(ctx = SSL_CTX_new(SSLv23_server_method())) ||
            !SSL_CTX_use_certificate_file(ctx, av[3], SSL_FILETYPE_PEM) ||
               !SSL_CTX_use_PrivateKey_file(ctx, av[3], SSL_FILETYPE_PEM) ||
                                          !SSL_CTX_check_private_key(ctx) ) {
         ERR_print_errors_fp(stderr);
         giveup("SSL init");
      }
      ssl = SSL_new(ctx),  gate = "Gate: https %s\r\n";
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
         if (n)
            close(cli);
         else {
            int fd, port;
            char *p, *q, buf[32768], buf2[64];

            close(sd);

            alarm(60);
            if (ssl) {
               SSL_set_fd(ssl, cli);
               if (SSL_accept(ssl) < 0)
                  return 1;
               n = SSL_read(ssl, buf, sizeof(buf));
            }
            else
               n = read(cli, buf, sizeof(buf));
            alarm(0);
            if (n < 6)
               return 1;

            /* "@8080 "
             * "GET /url HTTP/1.x"
             * "GET /8080/url HTTP/1.x"
             * "POST /url HTTP/1.x"
             * "POST /8080/url HTTP/1.x"
             */
            if (buf[0] == '@')
               p = buf + 1;
            else if (pre(buf, "GET /"))
               p = buf + 5;
            else if (pre(buf, "POST /"))
               p = buf + 6;
            else
               return 1;

            port = (int)strtol(p, &q, 10);
            if (q == p  ||  *q != ' ' && *q != '/')
               port = ports[0],  q = p;
            else if (port < cnt)
               port = ports[port];
            else if (port < 1024)
               return 1;

            if ((srv = gateConnect((unsigned short)port)) < 0) {
               if (!memchr(q,'~', buf + n - q))
                  return 1;
               if ((fd = open("void", O_RDONLY)) < 0)
                  return 1;
               alarm(60);
               if (ssl)
                  sslWrite(ssl, Head_200, strlen(Head_200));
               else
                  wrBytes(cli, Head_200, strlen(Head_200));
               alarm(0);
               while ((n = read(fd, buf, sizeof(buf))) > 0) {
                  alarm(60);
                  if (ssl)
                     sslWrite(ssl, buf, n);
                  else
                     wrBytes(cli, buf, n);
                  alarm(0);
               }
               return 0;
            }
            if (buf[0] == '@')
               p = q + 1;
            else {
               wrBytes(srv, buf, p - buf);
               if (*q == '/')
                  ++q;
               p = q;
               while (*p++ != '\n')
                  if (p >= buf + n)
                     return 1;
               wrBytes(srv, q, p - q);
               wrBytes(srv, buf2, sprintf(buf2, gate, inet_ntoa(addr.sin_addr)));
            }
            wrBytes(srv, p, buf + n - p);

            signal(SIGALRM, doSigAlarm);
            if (Buddy = fork()) {
               if (ssl)
                  while (alarm(60), (n = SSL_read(ssl, buf, sizeof(buf))) > 0)
                     alarm(0),  wrBytes(srv, buf, n);
               else
                  while (alarm(60), (n = read(cli, buf, sizeof(buf))) > 0)
                     alarm(0),  wrBytes(srv, buf, n);
               alarm(0);
               shutdown(cli, SHUT_RD);
               shutdown(srv, SHUT_WR);
            }
            else {
               Buddy = getppid();
               while ((n = read(srv, buf, sizeof(buf))) > 0) {
                  alarm(60);
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
      }
   }
}
