# 07sep11abu
# Amit Kulkarni <amitkulz@gmail.com>
# (c) Software Lab. Alexander Burger

# errno
(equ ENOENT 2)       # No such file or directory
(equ EINTR 4)        # Interrupted system call
(equ EBADF 9)        # Bad file number
(equ EAGAIN 35)      # Try again
(equ EACCES 13)      # Permission denied
(equ EPIPE 32)       # Broken pipe
(equ ECONNRESET 54)  # Connection reset by peer

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

(equ stdin  "$__sF")
(equ stdout "$__sF+152")
(equ stderr "$__sF+304")

(equ MAXPATHLEN 1024)

# dlfcn
(equ RTLD_LAZY 1)
(equ RTLD_GLOBAL 256)

# fcntl
(equ FLOCK 32)    # File lock structure
(equ L_TYPE 0)  # 2
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
(equ S_IFMT (hex "F000"))
(equ S_IFDIR (hex "4000"))

# times
(equ TMS 32)  # 'times' structure
(equ TMS_UTIME 0)
(equ TMS_STIME 8)

# termios
(equ TERMIOS (+ 44 4))  # Terminal I/O structure (+ Padding)
(equ C_IFLAG 0)
(equ C_LFLAG 12)
(equ C_CC 16)
(equ ISIG 128)
(equ VMIN 16)
(equ VTIME 17)
(equ TCSADRAIN 1)

# signal
(equ SIGACTION 16)  # Sigaction structure
(equ SIGSET_T 8)    # 4 -> aligned to word size
(equ SA_HANDLER 0)
(equ SA_MASK 8)
(equ SA_FLAGS 12)

(equ SIG_DFL 0)
(equ SIG_IGN 1)
(equ SIG_UNBLOCK 2)

(equ SIGHUP 1)  # Signals
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
(equ SIGNALS 31)  # Highest used signal number plus 1

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
(equ D_NAME 8)

# Sockets
(equ HOSTENT 32)
(equ H_NAME 0)
(equ H_LENGTH 20)
(equ H_ADDR_LIST 24)

(equ IN_ADDR 4)
(equ S_ADDR 0)

(equ SOCKADDR_IN 32)
(equ SIN_ADDR 4)
(equ SIN_ADDR.S_ADDR 4)
(equ SIN_PORT 2)
(equ SIN_FAMILY 1)
(equ AF_INET 2)
(equ SOCK_STREAM 1)
(equ SOCK_DGRAM 2)
(equ INADDR_ANY 0)
(equ SOL_SOCKET 65535)
(equ SO_REUSEADDR 4)

# vi:et:ts=3:sw=3
