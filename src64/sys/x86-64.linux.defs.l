# 11feb16abu
# (c) Software Lab. Alexander Burger

# errno
(equ ENOENT 2)       # No such file or directory
(equ EINTR 4)        # Interrupted system call
(equ EBADF 9)        # Bad file number
(equ EAGAIN 11)      # Try again
(equ EACCES 13)      # Permission denied
(equ EPIPE 32)       # Broken pipe
(equ ECONNRESET 104) # Connection reset by peer

# open/fcntl
(equ O_RDONLY 0)
(equ O_WRONLY 1)
(equ O_RDWR 2)
(equ O_CREAT 64)
(equ O_EXCL 128)
(equ O_TRUNC 512)
(equ O_APPEND 1024)
(equ F_GETFD 1)
(equ F_SETFD 2)
(equ FD_CLOEXEC 1)

# stdio
(equ BUFSIZ 8192)
(equ PIPE_BUF 4096)

(equ GETCWDLEN 0)

# dlfcn
(equ RTLD_LAZY 1)
(equ RTLD_GLOBAL 256)

# fcntl
(equ FLOCK 32)    # File lock structure
(equ L_TYPE 0)    # 2
(equ L_WHENCE 2)  # 2
(equ L_START 8)
(equ L_LEN 16)
(equ L_PID 24)
(equ SEEK_SET 0)
(equ SEEK_CUR 1)
(equ F_RDLCK 0)
(equ F_WRLCK 1)
(equ F_UNLCK 2)
(equ F_GETFL 3)
(equ F_SETFL 4)
(equ F_GETLK 5)
(equ F_SETLK 6)
(equ F_SETLKW 7)
(equ F_SETOWN 8)
(equ O_NONBLOCK 2048)
(equ O_ASYNC 8192)

# stat
(equ STAT 144)    # File status structure
(equ ST_MODE 24)  # 4
(equ ST_SIZE 48)
(equ ST_MTIME 88)
(equ S_IFMT  (oct "170000"))
(equ S_IFREG (oct "100000"))
(equ S_IFDIR (oct "40000"))

# times
(equ TMS 32)  # 'times' structure
(equ TMS_UTIME 0)
(equ TMS_STIME 8)

# termios
(equ TERMIOS 60)  # Terminal I/O structure
(equ C_IFLAG 0)
(equ C_OFLAG 4)
(equ C_CFLAG 8)
(equ C_LFLAG 12)
(equ C_CC 17)
(equ OPOST 1)
(equ ONLCR 4)
(equ ISIG 1)
(equ VMIN 6)
(equ VTIME 5)
(equ TCSADRAIN 1)

# signal
(equ SIGACTION 152)  # Sigaction structure
(equ SIGSET_T 128)
(equ SA_HANDLER 0)
(equ SA_MASK 8)
(equ SA_FLAGS 136)

(equ SIG_DFL 0)
(equ SIG_IGN 1)
(equ SIG_UNBLOCK 1)

(equ SIGHUP 1)  # Signals
(equ SIGINT 2)
(equ SIGUSR1 10)
(equ SIGUSR2 12)
(equ SIGPIPE 13)
(equ SIGALRM 14)
(equ SIGTERM 15)
(equ SIGCHLD 17)
(equ SIGCONT 18)
(equ SIGSTOP 19)
(equ SIGTSTP 20)
(equ SIGTTIN 21)
(equ SIGTTOU 22)
(equ SIGIO 29)
(equ SIGNALS 30)  # Highest used signal number plus 1

# wait
(equ WNOHANG 1)
(equ WUNTRACED 2)

# select
(equ FD_SET 128)  # 1024 bit

# time
(equ TM_SEC 0)
(equ TM_MIN 4)
(equ TM_HOUR 8)
(equ TM_MDAY 12)
(equ TM_MON 16)
(equ TM_YEAR 20)

# dir
(equ D_NAME 19)

# Sockets
(equ SOCK_STREAM 1)
(equ SOCK_DGRAM 2)
(equ AF_UNSPEC 0)
(equ AF_UNIX 1)
(equ AF_INET6 10)
(equ SOL_SOCKET 1)
(equ SO_REUSEADDR 2)
(equ IPPROTO_IPV6 41)
(equ IPV6_V6ONLY 26)
(equ INET6_ADDRSTRLEN 46)

(equ NI_MAXHOST 1025)
(equ NI_NAMEREQD 8)

(equ SOCKADDR_IN6 28)
(equ SIN6_FAMILY 0)
(equ SIN6_PORT 2)
(equ SIN6_ADDR 8)

(equ ADDRINFO 48)
(equ AI_FAMILY 4)
(equ AI_SOCKTYPE 8)
(equ AI_ADDRLEN 16)
(equ AI_ADDR 24)
(equ AI_NEXT 40)

# vi:et:ts=3:sw=3
