/* 17jan05abu
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

#include <openssl/pem.h>
#include <openssl/ssl.h>
#include <openssl/err.h>

typedef enum {NO,YES} bool;

static char Head_200[] =
   "HTTP/1.1 200 OK\r\n"
   "Server: PicoLisp\r\n"
   "Connection: close\r\n"
   "Content-Type: text/html; charset=utf-8\r\n";

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

static int gateSocket(void) {
   int sd;

   if ((sd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
      exit(1);
   return sd;
}

static int gatePort(int port) {
   int sd;
   struct sockaddr_in addr;

   bzero((char*)&addr, sizeof(addr));
   addr.sin_family = AF_INET;
   addr.sin_addr.s_addr = htonl(INADDR_ANY);
   addr.sin_port = htons((unsigned short)port);
   sd = gateSocket();
   if (bind(sd, (struct sockaddr*)&addr, sizeof(addr)) < 0)
      exit(1);
   if (listen(sd,5) < 0)
      exit(1);
   return sd;
}

static int gateConnect(unsigned short port) {
   int sd;
   struct sockaddr_in addr;

   bzero((char*)&addr, sizeof(addr));
   addr.sin_addr.s_addr = inet_addr("127.0.0.1");
   sd = gateSocket();
   addr.sin_family = AF_INET;
   addr.sin_port = htons(port);
   return connect(sd, (struct sockaddr*)&addr, sizeof(addr)) < 0? -1 : sd;
}

int main(int ac, char *av[]) {
   int n, fd, sd, dflt, port, cli, srv;
   struct sockaddr_in addr;
   char *gate, *p, *q, buf[BUFSIZ], buf2[64];
   SSL_CTX *ctx;
   SSL *ssl;
   fd_set fdSet;

   if (ac < 3 || ac > 4)
      giveup("port dflt [pem]");

   sd = gatePort((int)atol(av[1]));  // e.g. 80 or 443 / 9090
   dflt = (int)atol(av[2]);  // e.g. 8080
   if (ac == 3)
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

   signal(SIGCHLD,SIG_IGN);  /* Prevent zombies (Linux) */
   if ((n = fork()) < 0)
      giveup("detach");
   if (n)
      return 0;
   setsid();

   for (;;) {
      FD_ZERO(&fdSet);
      FD_SET(sd, &fdSet);
      if (select(sd+1, &fdSet, NULL, NULL, NULL) < 0)
         return 1;
      if (FD_ISSET(sd, &fdSet)) {
         n = sizeof(addr);
         if ((cli = accept(sd, (struct sockaddr*)&addr, &n)) < 0)
            return 1;
         if ((n = fork()) < 0)
            return 1;
         if (n)
            close(cli);
         else {
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

            /* "GET /url HTTP/1.1"
             * "GET /8080/url HTTP/1.1"
             * "POST /url HTTP/1.1"
             * "POST /8080/url HTTP/1.1"
             */
            if (pre(buf, "GET /"))
               p = buf + 5;
            else if (pre(buf, "POST /"))
               p = buf + 6;
            else
               return 1;

            port = (int)strtol(p, &q, 10);
            if (q == p  ||  *q != ' ' && *q != '/')
               port = dflt,  q = p;

            if ((srv = gateConnect((unsigned short)port)) < 0) {
               if (!memchr(q,'~', buf + n - q))
                  return 1;
               if ((fd = open("void", O_RDONLY)) < 0)
                  return 1;
               alarm(60);
               if (ssl)
                  SSL_write(ssl, Head_200, strlen(Head_200));
               else
                  wrBytes(cli, Head_200, strlen(Head_200));
               alarm(0);
               while ((n = read(fd, buf, sizeof(buf))) > 0) {
                  alarm(60);
                  if (ssl)
                     SSL_write(ssl, buf, n);
                  else
                     wrBytes(cli, buf, n);
                  alarm(0);
               }
               return 0;
            }
            wrBytes(srv, buf, p - buf);
            if (*q == '/')
               ++q;
            p = q;
            while (*p++ != '\n')
               if (p >= buf + n)
                  return 1;
            wrBytes(srv, q, p - q);
            wrBytes(srv, buf2, sprintf(buf2, gate, inet_ntoa(addr.sin_addr)));
            wrBytes(srv, p, buf + n - p);

            for (;;) {
               FD_ZERO(&fdSet);
               FD_SET(cli, &fdSet);
               FD_SET(srv, &fdSet);
               if (select((srv>cli? srv:cli)+1, &fdSet, NULL, NULL, NULL) < 0)
                  return 1;
               if (FD_ISSET(cli, &fdSet)) {
                  alarm(60);
                  if (ssl)
                     n = SSL_read(ssl, buf, sizeof(buf));
                  else
                     n = read(cli, buf, sizeof(buf));
                  alarm(0);
                  if (n <= 0)
                     return 0;
                  wrBytes(srv, buf, n);
               }
               if (FD_ISSET(srv, &fdSet)) {
                  if ((n = read(srv, buf, sizeof(buf))) <= 0)
                     return 0;
                  alarm(60);
                  if (ssl)
                     SSL_write(ssl, buf, n);
                  else
                     wrBytes(cli, buf, n);
                  alarm(0);
               }
            }
         }
      }
   }
}
