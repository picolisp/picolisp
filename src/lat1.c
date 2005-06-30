/* lat1.c
 * 31mar05abu
 * Convert stdin (UTF-8, 2-Byte) to process or file (ISO-8859-15)
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <sys/wait.h>

// lat1 [-<cmd> [<arg> ..]]
// lat1 [[+]<Outfile/ISO-8859-15>]
int main(int ac, char *av[]) {
	int c;
   pid_t pid = 0;
   FILE *fp = stdout;

   if (ac > 1) {
      char *mode = "w";

      if (*av[1] == '-') {
         int pfd[2];

         if (pipe(pfd) < 0) {
            fprintf(stderr, "lat1: Pipe error\n");
            return 1;
         }
         if ((pid = fork()) == 0) {
            close(pfd[1]);
            if (pfd[0] != STDIN_FILENO)
               dup2(pfd[0], STDIN_FILENO),  close(pfd[0]);
            execvp(av[1]+1, av+1);
         }
         if (pid < 0) {
            fprintf(stderr, "lat1: Fork error\n");
            return 1;
         }
         close(pfd[0]);
         if (!(fp = fdopen(pfd[1], mode))) {
            fprintf(stderr, "lat1: Pipe open error\n");
            return 1;
         }
      }
      else {
         if (*av[1] == '+')
            mode = "a",  ++av[1];
         if (!(fp = fopen(av[1], mode))) {
            fprintf(stderr, "lat1: '%s' open error\n", av[1]);
            return 1;
         }
      }
   }
	while ((c = getchar_unlocked()) != EOF) {
      if ((c & 0x80) == 0)
         putc_unlocked(c,fp);
      else if ((c & 0x20) == 0)
         putc_unlocked((c & 0x1F) << 6 | getchar_unlocked() & 0x3F, fp);
      else {
         getchar_unlocked(); // 0x82
         getchar_unlocked(); // 0xAC
         putc_unlocked(0xA4, fp);
      }
	}
   if (pid) {
      fclose(fp);
      while (waitpid(pid, NULL, 0) < 0)
         if (errno != EINTR) {
            fprintf(stderr, "lat1: Pipe close error\n");
            return 1;
         }
   }
   return 0;
}
