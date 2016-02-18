# 11feb16abu
# Mansur Mamkin <mmamkin@mail.ru>

# errno
(equ ENOENT 2)
(equ EINTR 4)
(equ EBADF 9)
(equ EAGAIN 35)
(equ EACCES 13)
(equ EPIPE 32)
(equ ECONNRESET 54)

# open/fcntl
(equ O_RDONLY 0)
(equ O_WRONLY 1)
(equ O_RDWR 2)
(equ O_CREAT 512)
(equ O_EXCL 2048)
(equ O_TRUNC 1024)
(equ O_APPEND 8)
(equ F_GETFD 1)
(equ F_SETFD 2)
(equ FD_CLOEXEC 1)

# stdio
(equ BUFSIZ 1024)
(equ PIPE_BUF 512)
(equ GETCWDLEN 0)
(equ stdin  "$__stdinp")
(equ stdout "$__stdoutp")
(equ stderr "$__stderrp")


# dlfcn
(equ RTLD_LAZY 1)
(equ RTLD_GLOBAL 256)

# fcntl
(equ FLOCK 32)
(equ L_TYPE 20)
(equ L_WHENCE 22)
(equ L_START 0)
(equ L_LEN 8)
(equ L_PID 16)
(equ SEEK_SET 0)
(equ SEEK_CUR 1)
(equ F_RDLCK 1)
(equ F_WRLCK 3)
(equ F_UNLCK 2)
(equ F_GETFL 3)
(equ F_SETFL 4)
(equ F_GETLK 11)
(equ F_SETLK 12)
(equ F_SETLKW 13)
(equ F_SETOWN 6)
(equ O_NONBLOCK 4)
(equ O_ASYNC 64)

# stat
(equ STAT 120)
(equ ST_MODE 8)
(equ ST_SIZE 72)
(equ ST_MTIME 40)
(equ S_IFMT  (oct "170000"))
(equ S_IFREG (oct "100000"))
(equ S_IFDIR (oct "40000"))

# times
(equ TMS 16)
(equ TMS_UTIME 0)
(equ TMS_STIME 4)

# termios
(equ TERMIOS 44)
(equ C_IFLAG 0)
(equ C_OFLAG 4)
(equ C_CFLAG 8)
(equ C_LFLAG 12)
(equ C_CC 16)
(equ OPOST 1)
(equ ONLCR 2)
(equ ISIG 128)
(equ VMIN 16)
(equ VTIME 17)
(equ TCSADRAIN 1)

# signal
(equ SIGACTION 32)
(equ SIGSET_T 16)
(equ SA_HANDLER 0)
(equ SA_MASK 12)
(equ SA_FLAGS 8)
(equ SIG_DFL 0)
(equ SIG_IGN 1)
(equ SIG_UNBLOCK 2)
(equ SIGHUP 1)
(equ SIGINT 2)
(equ SIGUSR1 30)
(equ SIGUSR2 31)
(equ SIGPIPE 13)
(equ SIGALRM 14)
(equ SIGTERM 15)
(equ SIGCHLD 20)
(equ SIGCONT 19)
(equ SIGSTOP 17)
(equ SIGTSTP 18)
(equ SIGTTIN 21)
(equ SIGTTOU 22)
(equ SIGIO 23)
(equ SIGNALS 32)

# wait
(equ WNOHANG 1)
(equ WUNTRACED 2)

# select
(equ FD_SET 128)

# time
(equ TM_SEC 0)
(equ TM_MIN 4)
(equ TM_HOUR 8)
(equ TM_MDAY 12)
(equ TM_MON 16)
(equ TM_YEAR 20)

# dir
(equ D_NAME 8)

# Sockets
(equ SOCK_STREAM 1)
(equ SOCK_DGRAM 2)
(equ AF_UNSPEC 0)
(equ AF_UNIX 1)
(equ AF_INET6 28)
(equ SOL_SOCKET 65535)
(equ SO_REUSEADDR 4)
(equ IPPROTO_IPV6 41)
(equ IPV6_V6ONLY 27)
(equ INET6_ADDRSTRLEN 46)
(equ NI_MAXHOST 1025)
(equ NI_NAMEREQD 4)
(equ SOCKADDR_IN6 28)
(equ SIN6_FAMILY 1)
(equ SIN6_PORT 2)
(equ SIN6_ADDR 8)
(equ ADDRINFO 48)
(equ AI_FAMILY 4)
(equ AI_SOCKTYPE 8)
(equ AI_ADDRLEN 16)
(equ AI_ADDR 32)
(equ AI_NEXT 40)

# vi:et:ts=3:sw=3
