/* 23sep05abu
 * (c) Software Lab. Alexander Burger
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <signal.h>
#include <netdb.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/tcp.h>
#include <netinet/in.h>

#include <openssl/pem.h>
#include <openssl/ssl.h>
#include <openssl/err.h>

typedef enum {NO,YES} bool;

static char *File, *Data;
static off_t Size;

static char Get[] =
   "GET /%s HTTP 1.1\r\n"
   "Connection: close\r\n"
   "User-Agent: PicoLisp\r\n"
   "Host: %s:%s\r\n"
   "Accept-Charset: utf-8\r\n\r\n";

static void errmsg(char *msg) {
   fprintf(stderr, "ssl: %s\n", msg);
}

static void giveup(char *msg) {
   errmsg(msg);
   exit(1);
}

static void sslChk(int n) {
   if (n < 0) {
      ERR_print_errors_fp(stderr);
      exit(1);
   }
}

static int sslConnect(SSL *ssl, char *host, int port) {
   struct sockaddr_in addr;
   struct hostent *p;
   int sd;

   memset(&addr, 0, sizeof(addr));
   if ((long)(addr.sin_addr.s_addr = inet_addr(host)) == -1) {
      if (!(p = gethostbyname(host))  ||  p->h_length == 0)
         return -1;
      addr.sin_addr.s_addr = ((struct in_addr*)p->h_addr_list[0])->s_addr;
   }

   if ((sd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
      errmsg("No socket");
      return -1;
   }
   addr.sin_family = AF_INET;
   addr.sin_port = htons((unsigned short)port);
   if (connect(sd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
      close(sd);
      return -1;
   }

   SSL_set_fd(ssl,sd);
   if (SSL_connect(ssl) >= 0)
      return sd;
   close(sd);
   return -1;
}

static bool sslClose(SSL *ssl, int sd) {
   int n;

   do
      if ((n = SSL_shutdown(ssl)) == 1)
         return close(sd) == 0;
   while (n == 0);
   return NO;
}

static bool sslFile(SSL *ssl, char *file) {
   int fd, n;
   char buf[BUFSIZ];

   if (file[0] == '-')
      return SSL_write(ssl, file+1, strlen(file)-1) >= 0;
   if ((fd = open(file, O_RDONLY)) < 0)
      return NO;
   while ((n = read(fd, buf, sizeof(buf))) > 0)
      if (SSL_write(ssl, buf, n) < 0) {
         close(fd);
         return NO;
      }
   close(fd);
   return n == 0;
}

static void doSigTerm(int n __attribute__((unused))) {
   int fd1, fd2, cnt;
   char buf[BUFSIZ];

   if (Data  &&  (fd1 = open(File, O_RDWR)) >= 0) {
      if (unlink(File) < 0)
         giveup("Can't unlink back");
      if ((fd2 = open(File, O_CREAT|O_WRONLY|O_TRUNC, 0666)) < 0)
         giveup("Can't create back");
      if (write(fd2, Data, Size) != Size)
         giveup("Can't write back");
      while ((cnt = read(fd1, buf, sizeof(buf))) > 0)
         write(fd2, buf, cnt);
   }
   exit(0);
}

// ssl host port url
// ssl host port url file
// ssl host port url key file
// ssl host port url key file sec
int main(int ac, char *av[]) {
   SSL_CTX *ctx;
   SSL *ssl;
   int n, sec, getLen, lenLen, fd, sd;
   struct stat st;
   struct flock fl;
   char get[1024], buf[BUFSIZ], len[64];

   if (ac < 4 || ac > 7)
      giveup("host port url [[key] file [sec]]");
   if (strlen(Get)+strlen(av[1])+strlen(av[2])+strlen(av[3]) >= sizeof(get))
      giveup("Names too long");
   getLen = sprintf(get, Get, av[3], av[1], av[2]);

   SSL_load_error_strings();
   OpenSSL_add_ssl_algorithms();
   if (!(ctx = SSL_CTX_new(SSLv2_client_method()))) {
      ERR_print_errors_fp(stderr);
      giveup("SSL init");
   }
   ssl = SSL_new(ctx);

   if (ac <= 6) {
      if (sslConnect(ssl, av[1], (int)atol(av[2])) < 0) {
         errmsg("Can't connect");
         return 1;
      }
      sslChk(SSL_write(ssl, get, getLen));
      if (ac > 4) {
         if (*av[4]  &&  !sslFile(ssl,av[4]))
            giveup(av[4]);
         if (ac > 5  &&  *av[5]  &&  !sslFile(ssl,av[5]))
            giveup(av[5]);
      }
      while ((n = SSL_read(ssl, buf, sizeof(buf))) > 0)
         write(STDOUT_FILENO, buf, n);
      return 0;
   }
   File = av[5];
   sec = (int)atol(av[6]);
   signal(SIGINT, doSigTerm);
   signal(SIGTERM, doSigTerm);
   signal(SIGPIPE, SIG_IGN);
   for (;;) {
      if ((fd = open(File, O_RDWR)) < 0)
         sleep(sec);
      else if (fstat(fd,&st) < 0  ||  st.st_size == 0)
         close(fd),  sleep(sec);
      else {
         fl.l_type = F_WRLCK;
         fl.l_whence = SEEK_SET;
         fl.l_start = 0;
         fl.l_len = 0;
         if (fcntl(fd, F_SETLKW, &fl) < 0)
            giveup("Can't lock");
         if (fstat(fd,&st) < 0  ||  (Size = st.st_size) == 0)
            giveup("Can't access");
         lenLen = sprintf(len, "%lld\n", Size);
         if ((Data = malloc(Size)) == NULL)
            giveup("Can't alloc");
         if (read(fd, Data, Size) != Size)
            giveup("Can't read");
         if (ftruncate(fd,0) < 0)
            errmsg("Can't truncate");
         close(fd);
         for (;;) {
            if ((sd = sslConnect(ssl, av[1], (int)atol(av[2]))) >= 0) {
               buf[0] = 'T';
               if (SSL_write(ssl, get, getLen) == getLen  &&
                        (!*av[4] || sslFile(ssl,av[4]))  &&          // key
                        SSL_write(ssl, len, lenLen) == lenLen  &&    // length
                        SSL_write(ssl, Data, Size) == Size  &&       // data
                        SSL_write(ssl, buf, 1) == 1 &&               // ack
                        SSL_read(ssl, buf, 1) == 1  &&  buf[0] == 'T'  &&
                        sslClose(ssl,sd) )
                  break;

               sslClose(ssl,sd);
            }
            sleep(sec);
         }
         free(Data),  Data = NULL;
      }
   }
}
