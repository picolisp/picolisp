/* 13nov02abu
 * (c) Software Lab. Alexander Burger
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
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

static char Get[] =
   "GET /%s HTTP 1.1\n"
   "Connection: close\n"
   "Host: %s:%d\n"
   "User-Agent: PicoLisp\n"
   "Accept:  text/html\n"
   "Accept-Charset: utf-8\n\n";

static char Post[] =
   "POST /%s HTTP 1.1\n"
   "Connection: close\n"
   "Host: %s:%d\n"
   "User-Agent: PicoLisp\n"
   "Accept:  text/html\n"
   "Accept-Charset: utf-8\n"
   "Content-type: application/x-www-form-urlencoded\n"
   "Content-length: %d\n\n%s";

static void giveup(char *msg) {
   fprintf(stderr, "ssl: %s\n", msg);
   exit(1);
}

static void chk(int n) {
   if (n < 0) {
      ERR_print_errors_fp(stderr);
      exit(1);
   }
}

int main(int ac, char *av[]) {
   SSL_CTX *ctx;
   SSL *ssl;
   int sd, n;
   struct sockaddr_in addr;
   struct hostent *p;
   char buf[4096];

   if (ac < 4)
      giveup("host port name/get [data/post]");
   if (strlen(av[3]) >= sizeof(buf)-1024)
      giveup("Name too long");
   SSL_load_error_strings();
   OpenSSL_add_ssl_algorithms();
   if (!(ctx = SSL_CTX_new(SSLv2_client_method()))) {
      ERR_print_errors_fp(stderr);
      giveup("SSL init");
   }
   ssl = SSL_new(ctx);

   bzero((char*)&addr, sizeof(addr));
   if ((long)(addr.sin_addr.s_addr = inet_addr(av[1])) == -1) {
      if (!(p = gethostbyname(av[1]))  ||  p->h_length == 0)
         giveup("Can't get host");
      addr.sin_addr.s_addr = ((struct in_addr*)p->h_addr_list[0])->s_addr;
   }

   if ((sd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
      giveup("No socket");
   addr.sin_family = AF_INET;
   addr.sin_port = htons((short)atol(av[2]));
   if (connect(sd, (struct sockaddr*)&addr, sizeof(addr)) < 0)
      giveup("Can't connect");

   SSL_set_fd(ssl,sd);
   chk(SSL_connect(ssl));

   if (ac == 4)
      sprintf(buf, Get, av[3], av[1], (int)atol(av[2]));
   else
      sprintf(buf, Post, av[3], av[1], (int)atol(av[2]), strlen(av[4]), av[4]);
   chk(SSL_write(ssl, buf, strlen(buf)));

   while ((n = SSL_read(ssl, buf, sizeof(buf))) > 0)
      write(STDOUT_FILENO, buf, n);

   SSL_shutdown(ssl);
   return 0;
}
