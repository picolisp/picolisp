/* 11feb16abu
 * (c) Software Lab. Alexander Burger
 */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <limits.h>
#include <errno.h>
#include <fcntl.h>
#include <dirent.h>
#include <signal.h>
#include <dlfcn.h>
#include <time.h>
#include <poll.h>
#include <termios.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/times.h>
#include <sys/resource.h>
#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>

#ifndef O_ASYNC
#define O_ASYNC 0
#endif

static int SigNums[] = {
   SIGHUP, SIGINT, SIGUSR1, SIGUSR2, SIGPIPE, SIGALRM, SIGTERM,
   SIGCHLD, SIGCONT, SIGSTOP, SIGTSTP, SIGTTIN, SIGTTOU, SIGIO
};

static char *SigNames[] = {
   "SIGHUP", "SIGINT", "SIGUSR1", "SIGUSR2", "SIGPIPE", "SIGALRM", "SIGTERM",
   "SIGCHLD", "SIGCONT", "SIGSTOP", "SIGTSTP", "SIGTTIN", "SIGTTOU", "SIGIO"
};

static void comment(char *s) {
   printf("\n# %s\n", s);
}

static void equ(char *sym, long val) {
   printf("(equ %s %ld)\n", sym, val);
}

int main(void) {
   int i, n;
   struct flock fl;
   struct stat st;
   struct tms tim;
   struct termios term;
   struct sigaction act;
   fd_set rdSet;
   struct tm tm;
   struct dirent dir;
   struct sockaddr_in6 addr;
   struct addrinfo ai;

   i = 1;
   printf("# Endianess\n%c\n# Wordsize\n%d\n",
      *(char*)&i == 1? 'L' : 'B', (int)sizeof(char*) * 8 );

   comment("errno");
   equ("ENOENT", ENOENT);
   equ("EINTR", EINTR);
   equ("EBADF", EBADF);
   equ("EAGAIN", EAGAIN);
   equ("EACCES", EACCES);
   equ("EPIPE", EPIPE);
   equ("ECONNRESET", ECONNRESET);

   comment("open/fcntl");
   equ("O_RDONLY", O_RDONLY);
   equ("O_WRONLY", O_WRONLY);
   equ("O_RDWR", O_RDWR);
   equ("O_CREAT", O_CREAT);
   equ("O_EXCL", O_EXCL);
   equ("O_TRUNC", O_TRUNC);
   equ("O_APPEND", O_APPEND);
   equ("F_GETFD", F_GETFD);
   equ("F_SETFD", F_SETFD);
   equ("FD_CLOEXEC", FD_CLOEXEC);

   comment("stdio");
   equ("BUFSIZ", BUFSIZ);
   equ("PIPE_BUF", PIPE_BUF);
   equ("GETCWDLEN", 0);  // getcwd(NULL, GETCWDLEN)

   comment("dlfcn");
   equ("RTLD_LAZY", RTLD_LAZY);
   equ("RTLD_GLOBAL", RTLD_GLOBAL);

   comment("fcntl");
   equ("FLOCK", sizeof(fl));
   equ("L_TYPE", (char*)&fl.l_type - (char*)&fl);
   equ("L_WHENCE", (char*)&fl.l_whence - (char*)&fl);
   equ("L_START", (char*)&fl.l_start - (char*)&fl);
   equ("L_LEN", (char*)&fl.l_len - (char*)&fl);
   equ("L_PID", (char*)&fl.l_pid - (char*)&fl);
   equ("SEEK_SET", SEEK_SET);
   equ("SEEK_CUR", SEEK_CUR);
   equ("F_RDLCK", F_RDLCK);
   equ("F_WRLCK", F_WRLCK);
   equ("F_UNLCK", F_UNLCK);
   equ("F_GETFL", F_GETFL);
   equ("F_SETFL", F_SETFL);
   equ("F_GETLK", F_GETLK);
   equ("F_SETLK", F_SETLK);
   equ("F_SETLKW", F_SETLKW);
   equ("F_SETOWN", F_SETOWN);
   equ("O_NONBLOCK", O_NONBLOCK);
   equ("O_ASYNC", O_ASYNC);

   comment("stat");
   equ("STAT", sizeof(st));
   equ("ST_MODE", (char*)&st.st_mode - (char*)&st);
   equ("ST_SIZE", (char*)&st.st_size - (char*)&st);
   equ("ST_MTIME", (char*)&st.st_mtime - (char*)&st);
   equ("S_IFMT", S_IFMT);
   equ("S_IFREG", S_IFREG);
   equ("S_IFDIR", S_IFDIR);

   comment("times");
   equ("TMS", sizeof(tim));
   equ("TMS_UTIME", (char*)&tim.tms_utime - (char*)&tim);
   equ("TMS_STIME", (char*)&tim.tms_stime - (char*)&tim);

   comment("termios");
   equ("TERMIOS", sizeof(term));
   equ("C_IFLAG", (char*)&term.c_iflag - (char*)&term);
   equ("C_OFLAG", (char*)&term.c_oflag - (char*)&term);
   equ("C_CFLAG", (char*)&term.c_cflag - (char*)&term);
   equ("C_LFLAG", (char*)&term.c_lflag - (char*)&term);
   equ("C_CC", (char*)&term.c_cc - (char*)&term);
   equ("OPOST", OPOST);
   equ("ONLCR", ONLCR);
   equ("ISIG", ISIG);
   equ("VMIN", VMIN);
   equ("VTIME", VTIME);
   equ("TCSADRAIN", TCSADRAIN);

   comment("signal");
   equ("SIGACTION", sizeof(act));
   equ("SIGSET_T", sizeof(sigset_t));
   equ("SA_HANDLER", (char*)&act.sa_handler - (char*)&act);
   equ("SA_MASK", (char*)&act.sa_mask - (char*)&act);
   equ("SA_FLAGS", (char*)&act.sa_flags - (char*)&act);

   equ("SIG_DFL", (long)SIG_DFL);
   equ("SIG_IGN", (long)SIG_IGN);
   equ("SIG_UNBLOCK", SIG_UNBLOCK);

   for (i = n = 0; i < sizeof(SigNums)/sizeof(int); ++i) {
      equ(SigNames[i], SigNums[i]);
      if (SigNums[i] > n)
         n = SigNums[i];
   }
   equ("SIGNALS", n + 1);  // Highest used signal number plus 1

   comment("wait");
   equ("WNOHANG", WNOHANG);
   equ("WUNTRACED", WUNTRACED);

   comment("select");
   equ("FD_SET", sizeof(rdSet));

   comment("time");
   equ("TM_SEC", (char*)&tm.tm_sec - (char*)&tm);
   equ("TM_MIN", (char*)&tm.tm_min - (char*)&tm);
   equ("TM_HOUR", (char*)&tm.tm_hour - (char*)&tm);
   equ("TM_MDAY", (char*)&tm.tm_mday - (char*)&tm);
   equ("TM_MON", (char*)&tm.tm_mon - (char*)&tm);
   equ("TM_YEAR", (char*)&tm.tm_year - (char*)&tm);

   comment("dir");
   equ("D_NAME", (char*)&dir.d_name - (char*)&dir);

   comment("Sockets");
   equ("SOCK_STREAM", SOCK_STREAM);
   equ("SOCK_DGRAM", SOCK_DGRAM);
   equ("AF_UNSPEC", AF_UNSPEC);
   equ("AF_UNIX", AF_UNIX);
   equ("AF_INET6", AF_INET6);
   equ("SOL_SOCKET", SOL_SOCKET);
   equ("SO_REUSEADDR", SO_REUSEADDR);
   equ("IPPROTO_IPV6", IPPROTO_IPV6);
   equ("IPV6_V6ONLY", IPV6_V6ONLY);
   equ("INET6_ADDRSTRLEN", INET6_ADDRSTRLEN);

   equ("NI_MAXHOST", NI_MAXHOST);
   equ("NI_NAMEREQD", NI_NAMEREQD);

   equ("SOCKADDR_IN6", sizeof(addr));
   equ("SIN6_FAMILY", (char*)&addr.sin6_family - (char*)&addr);
   equ("SIN6_PORT", (char*)&addr.sin6_port - (char*)&addr);
   equ("SIN6_ADDR", (char*)&addr.sin6_addr - (char*)&addr);

   equ("ADDRINFO", sizeof(ai));
   equ("AI_FAMILY", (char*)&ai.ai_family - (char*)&ai);
   equ("AI_SOCKTYPE", (char*)&ai.ai_socktype - (char*)&ai);
   equ("AI_ADDRLEN", (char*)&ai.ai_addrlen - (char*)&ai);
   equ("AI_ADDR", (char*)&ai.ai_addr - (char*)&ai);
   equ("AI_NEXT", (char*)&ai.ai_next - (char*)&ai);
}
