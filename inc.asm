%macro PUSHX 1-*
    %rep %0
        push %1
        %rotate 1
    %endrep
%endmacro

%macro POPX 1-*
    %rep %0
        %rotate -1
        pop %1
    %endrep
%endmacro    

%macro XORX 1-*
    %rep %0
        xor %1, %1
        %rotate 1
    %endrep
%endmacro

%ifdef PAYLOAD_OPTIMISED
    %macro opmov 1-2
        push %2
        pop %1
    %endmacro
%else
    %macro opmov 1-2
        mov %1, %2
    %endmacro
%endif

%define DT_REG 0x8
%define DT_DIR 0x4

%ifdef X86_32

%macro PUSHDQ 1
sub     esp, 16
movdqu  oword [esp], %1
%endmacro


%macro REL 1
call get_fixed_addr
add r5, %1 - reference
%endmacro

%macro OFILE 1-2
    lea ebx, %1
    mov ecx, %2
    mov eax, SYS_OPEN 
    int 0x80
%endmacro

%macro CFILE 1
    mov ebx, %1
    mov eax, SYS_CLOSE
    int 0x80
%endmacro

%macro RFILE 1-3
    mov ebx, %1
    lea ecx, %2
    mov edx, %3
    mov eax, SYS_READ
    int 0x80
%endmacro

%macro ODIR 1-3
    mov ebx, %1
    lea ecx, %2
    mov edx, %3
    mov eax, SYS_GETDENTS
    int 0x80
%endmacro

%macro EXIT 1
    mov ebx, %1
    mov eax, SYS_EXIT 
    syscall
%endmacro

%macro INIT_MX_VAR 0
mov ebp, esp
and esp, 0xfffffff0
sub esp, 0x4*8 
%endmacro

%macro DESTROY_MX_VAR 0
mov esp, ebp
xor ebp, ebp
%endmacro

%define r1 ebx
%define r2 ecx
%define r3 edx
%define r4 esi
%define r5 edi

%define r1b bl
%define r2b cl
%define r3b dl

%define r1w bp
%define r2w cx
%define r3w dx
%define r4w si
%define r5w di

%define r1d ebx
%define r2d ecx
%define r3d edx
%define r4d esi
%define r5d edi

%define rdi edi
%define rsi esi
%define rax eax
%define rdx edx
%define rcx ecx
%define rsp esp
%define rbp ebp
%define rbx ebx
%define resq   resd
%define movq   movd
%define dq dd
%define syscall int 0x80
%define qword dword
%define movsq movsd 

%define m0      [ebp]
%define m1      [ebp+0x4*1]
%define m2      [ebp+0x4*2]
%define m3      [ebp+0x4*3]
%define m4      [ebp+0x4*4]
%define m5      [ebp+0x4*5]
%define m6      [ebp+0x4*6]
%define m7      [ebp+0x4*7]

%define bytes   0x4

%else

%macro PUSHDQ 1
sub     rsp, 16
movdqu  oword [rsp], %1
%endmacro

%macro REL 1
lea r5, [%1]
%endmacro

%macro OFILE 1-2
    lea rdi, %1
    mov rsi, %2
    mov rax, SYS_OPEN
    syscall
%endmacro

%macro CFILE 1
    mov rdi, %1
    mov rax, SYS_CLOSE
    syscall
%endmacro

%macro RFILE 1-3
    mov rdi, %1
    lea rsi, %2
    mov rdx, %3
    mov eax, SYS_READ
    syscall
%endmacro

%macro ODIR 1-3
    mov rdi, %1
    lea rsi, %2
    mov rdx, %3
    mov rax, SYS_GETDENTS
    syscall
%endmacro

%macro EXIT 1
    mov rdi, %1
    mov rax, SYS_EXIT
    syscall
%endmacro

%macro INIT_MX_VAR 0
mov rbp, rsp
and rsp, 0xfffffffffffffff0
sub rsp, 0x8*8
%endmacro

%macro DESTROY_MX_VAR 0
mov rsp, rbp
xor rbp, rbp
%endmacro

%define r1 rdi
%define r2 rsi
%define r3 rdx
%define r4 r10
%define r5 r8

%define r1b dil
%define r2b sil
%define r3b dl

%define r1w di
%define r2w si 
%define r3w dx
%define r4w r10w
%define r5w r8w

%define r1d edi
%define r2d esi
%define r3d edx
%define r4d r10d
%define r5d r8d

%define m0      [rbp]
%define m1      [rbp+0x8*1]
%define m2      [rbp+0x8*2]
%define m3      [rbp+0x8*3]
%define m4      [rbp+0x8*4]
%define m5      [rbp+0x8*5]
%define m6      [rbp+0x8*6]
%define m7      [rbp+0x8*7]

%define bytes   0x8
%endif

struc linux_dirent
    .d_ino      resq    1
    .d_off      resq    1
    .d_reclen   resw    1
    .d_name     resb    255
endstruc

%ifdef X86_64
struc user_regs_struct
    .r15         resq 1
    .r14         resq 1
    .r13         resq 1
    .r12         resq 1
    .ebp         resq 1
    .ebx         resq 1
    .r11         resq 1
    .r10         resq 1
    .r9          resq 1
    .r8          resq 1
    .eax         resq 1
    .ecx         resq 1
    .edx         resq 1
    .esi         resq 1
    .edi         resq 1
    .orig_eax    resq 1
    .eip         resq 1
    .cs          resq 1
    .eflags      resq 1
    .esp         resq 1
    .ss          resq 1
    .fs_base     resq 1
    .gs_base     resq 1
    .ds          resq 1
    .es          resq 1
    .fs          resq 1
    .gs          resq 1
endstruc
%else
struc user_regs_struct
    .ebx         resd 1
    .ecx         resd 1
    .edx         resd 1
    .esi         resd 1
    .edi         resd 1
    .ebp         resd 1
    .eax         resd 1
    .xds         resd 1
    .xes         resd 1
    .xfs         resd 1
    .xgs         resd 1
    .orig_eax    resd 1
    .eip         resd 1
    .xcs         resd 1
    .eflags      resd 1
    .esp         resd 1
    .xss         resd 1
endstruc
%endif

struc sigaction
    .sa_handler   resq 1
    .sa_sigaction resq 1
    .sa_mask      resd 1
    .sa_flags     resd 1
    .sa_restorer  resq 1
endstruc

%define DIRENT_BUFSIZE 0x400

%ifdef X86_64
; Syscalls
%define SYS_READ 0
%define SYS_WRITE 1
%define SYS_OPEN 2
%define SYS_CLOSE 3
%define SYS_STAT 4
%define SYS_FSTAT 5
%define SYS_LSTAT 6
%define SYS_POLL 7
%define SYS_LSEEK 8
%define SYS_MMAP 9
%define SYS_MPROTECT 10
%define SYS_MUNMAP 11
%define SYS_BRK 12
%define SYS_RT_SIGACTION 13
%define SYS_RT_SIGPROCMASK 14
%define SYS_RT_SIGRETURN 15
%define SYS_IOCTL 16
%define SYS_PREAD64 17
%define SYS_PWRITE64 18
%define SYS_READV 19
%define SYS_WRITEV 20
%define SYS_ACCESS 21
%define SYS_PIPE 22
%define SYS_SELECT 23
%define SYS_SCHED_YIELD 24
%define SYS_MREMAP 25
%define SYS_MSYNC 26
%define SYS_MINCORE 27
%define SYS_MADVISE 28
%define SYS_SHMGET 29
%define SYS_SHMAT 30
%define SYS_SHMCTL 31
%define SYS_DUP 32
%define SYS_DUP2 33
%define SYS_PAUSE 34
%define SYS_NANOSLEEP 35
%define SYS_GETITIMER 36
%define SYS_ALARM 37
%define SYS_SETITIMER 38
%define SYS_GETPID 39
%define SYS_SENDFILE 40
%define SYS_SOCKET 41
%define SYS_CONNECT 42
%define SYS_ACCEPT 43
%define SYS_SENDTO 44
%define SYS_RECVFROM 45
%define SYS_SENDMSG 46
%define SYS_RECVMSG 47
%define SYS_SHUTDOWN 48
%define SYS_BIND 49
%define SYS_LISTEN 50
%define SYS_GETSOCKNAME 51
%define SYS_GETPEERNAME 52
%define SYS_SOCKETPAIR 53
%define SYS_SETSOCKOPT 54
%define SYS_GETSOCKOPT 55
%define SYS_CLONE 56
%define SYS_FORK 57
%define SYS_VFORK 58
%define SYS_EXECVE 59
%define SYS_EXIT 60
%define SYS_WAIT4 61
%define SYS_KILL 62
%define SYS_NEWUNAME 63
%define SYS_SEMGET 64
%define SYS_SEMOP 65
%define SYS_SEMCTL 66
%define SYS_SHMDT 67
%define SYS_MSGGET 68
%define SYS_MSGSND 69
%define SYS_MSGRCV 70
%define SYS_MSGCTL 71
%define SYS_FCNTL 72
%define SYS_FLOCK 73
%define SYS_FSYNC 74
%define SYS_FDATASYNC 75
%define SYS_TRUNCATE 76
%define SYS_FTRUNCATE 77
%define SYS_GETDENTS 78
%define SYS_GETCWD 79
%define SYS_CHDIR 80
%define SYS_FCHDIR 81
%define SYS_RENAME 82
%define SYS_MKDIR 83
%define SYS_RMDIR 84
%define SYS_CREAT 85
%define SYS_LINK 86
%define SYS_UNLINK 87
%define SYS_SYMLINK 88
%define SYS_READLINK 89
%define SYS_CHMOD 90
%define SYS_FCHMOD 91
%define SYS_CHOWN 92
%define SYS_FCHOWN 93
%define SYS_LCHOWN 94
%define SYS_UMASK 95
%define SYS_GETTIMEOFDAY 96
%define SYS_GETRLIMIT 97
%define SYS_GETRUSAGE 98
%define SYS_SYSINFO 99
%define SYS_TIMES 100
%define SYS_PTRACE 101
%define SYS_GETUID 102
%define SYS_SYSLOG 103
%define SYS_GETGID 104
%define SYS_SETUID 105
%define SYS_SETGID 106
%define SYS_GETEUID 107
%define SYS_GETEGID 108
%define SYS_SETPGID 109
%define SYS_GETPPID 110
%define SYS_GETPGRP 111
%define SYS_SETSID 112
%define SYS_SETREUID 113
%define SYS_SETREGID 114
%define SYS_GETGROUPS 115
%define SYS_SETGROUPS 116
%define SYS_SETRESUID 117
%define SYS_GETRESUID 118
%define SYS_SETRESGID 119
%define SYS_GETRESGID 120
%define SYS_GETPGID 121
%define SYS_SETFSUID 122
%define SYS_SETFSGID 123
%define SYS_GETSID 124
%define SYS_CAPGET 125
%define SYS_CAPSET 126
%define SYS_RT_SIGPENDING 127
%define SYS_RT_SIGTIMEDWAIT 128
%define SYS_RT_SIGQUEUEINFO 129
%define SYS_RT_SIGSUSPEND 130
%define SYS_SIGALTSTACK 131
%define SYS_UTIME 132
%define SYS_MKNOD 133
%define SYS_USELIB 134
%define SYS_PERSONALITY 135
%define SYS_USTAT 136
%define SYS_STATFS 137
%define SYS_FSTATFS 138
%define SYS_SYSFS 139
%define SYS_GETPRIORITY 140
%define SYS_SETPRIORITY 141
%define SYS_SCHED_SETPARAM 142
%define SYS_SCHED_GETPARAM 143
%define SYS_SCHED_SETSCHEDULER 144
%define SYS_SCHED_GETSCHEDULER 145
%define SYS_SCHED_GET_PRIORITY_MAX 146
%define SYS_SCHED_GET_PRIORITY_MIN 147
%define SYS_SCHED_RR_GET_INTERVAL 148
%define SYS_MLOCK 149
%define SYS_MUNLOCK 150
%define SYS_MLOCKALL 151
%define SYS_MUNLOCKALL 152
%define SYS_VHANGUP 153
%define SYS_MODIFY_LDT 154
%define SYS_PIVOT_ROOT 155
%define SYS_SYSCTL 156
%define SYS_PRCTL 157
%define SYS_ARCH_PRCTL 158
%define SYS_ADJTIMEX 159
%define SYS_SETRLIMIT 160
%define SYS_CHROOT 161
%define SYS_SYNC 162
%define SYS_ACCT 163
%define SYS_SETTIMEOFDAY 164
%define SYS_MOUNT 165
%define SYS_UMOUNT2 166
%define SYS_SWAPON 167
%define SYS_SWAPOFF 168
%define SYS_REBOOT 169
%define SYS_SETHOSTNAME 170
%define SYS_SETDOMAINNAME 171
%define SYS_IOPL 172
%define SYS_IOPERM 173
%define SYS_CREATE_MODULE 174
%define SYS_INIT_MODULE 175
%define SYS_DELETE_MODULE 176
%define SYS_GET_KERNEL_SYMS 177
%define SYS_QUERY_MODULE 178
%define SYS_QUOTACTL 179
%define SYS_NFSSERVCTL 180
%define SYS_GETPMSG 181
%define SYS_PUTPMSG 182
%define SYS_AFS_SYSCALL 183
%define SYS_TUXCALL 184
%define SYS_SECURITY 185
%define SYS_GETTID 186
%define SYS_READAHEAD 187
%define SYS_SETXATTR 188
%define SYS_LSETXATTR 189
%define SYS_FSETXATTR 190
%define SYS_GETXATTR 191
%define SYS_LGETXATTR 192
%define SYS_FGETXATTR 193
%define SYS_LISTXATTR 194
%define SYS_LLISTXATTR 195
%define SYS_FLISTXATTR 196
%define SYS_REMOVEXATTR 197
%define SYS_LREMOVEXATTR 198
%define SYS_FREMOVEXATTR 199
%define SYS_TKILL 200
%define SYS_TIME 201
%define SYS_FUTEX 202
%define SYS_SCHED_SETAFFINITY 203
%define SYS_SCHED_GETAFFINITY 204
%define SYS_SET_THREAD_AREA 205
%define SYS_IO_SETUP 206
%define SYS_IO_DESTROY 207
%define SYS_IO_GETEVENTS 208
%define SYS_IO_SUBMIT 209
%define SYS_IO_CANCEL 210
%define SYS_GET_THREAD_AREA 211
%define SYS_LOOKUP_DC 212
%define SYS_EPOLL_CREATE 213
%define SYS_EPOLL_CTL_OLD 214
%define SYS_EPOLL_WAIT_OLD 215
%define SYS_REMAP_FILE_PAGES 216
%define SYS_GETDENTS64 217
%define SYS_SET_TID_ADDRESS 218
%define SYS_RESTART_SYSCALL 219
%define SYS_SEMTIMEDOP 220
%define SYS_FADVISE64 221
%define SYS_TIMER_CREATE 222
%define SYS_TIMER_SETTIME 223
%define SYS_TIMER_GETTIME 224
%define SYS_TIMER_GETOVERRUN 225
%define SYS_TIMER_DELETE 226
%define SYS_CLOCK_SETTIME 227
%define SYS_CLOCK_GETTIME 228
%define SYS_CLOCK_GETRES 229
%define SYS_CLOCK_NANOSLEEP 230
%define SYS_EXIT_GROUP 231
%define SYS_EPOLL_WAIT 232
%define SYS_EPOLL_CTL 233
%define SYS_TGKILL 234
%define SYS_UTIMES 235
%define SYS_VSERVER 236
%define SYS_MBIND 237
%define SYS_SET_MEMPOLICY 238
%define SYS_GET_MEMPOLICY 239
%define SYS_MQ_OPEN 240
%define SYS_MQ_UNLINK 241
%define SYS_MQ_TIMEDSEND 242
%define SYS_MQ_TIMEDRECEIVE 243
%define SYS_MQ_NOTIFY 244
%define SYS_MQ_GETSETATTR 245
%define SYS_KEXEC_LOAD 246
%define SYS_WAITID 247
%define SYS_ADD_KEY 248
%define SYS_REQUEST_KEY 249
%define SYS_KEYCTL 250
%define SYS_IOPRIO_SET 251
%define SYS_IOPRIO_GET 252
%define SYS_INOTIFY_INIT 253
%define SYS_INOTIFY_ADD_WATCH 254
%define SYS_INOTIFY_RM_WATCH 255
%define SYS_MIGRATE_PAGES 256
%define SYS_OPENAT 257
%define SYS_MKDIRAT 258
%define SYS_MKNODAT 259
%define SYS_FCHOWNAT 260
%define SYS_FUTIMESAT 261
%define SYS_NEWFSTATAT 262
%define SYS_UNLINKAT 263
%define SYS_RENAMEAT 264
%define SYS_LINKAT 265
%define SYS_SYMLINKAT 266
%define SYS_READLINKAT 267
%define SYS_FCHMODAT 268
%define SYS_FACCESSAT 269
%define SYS_PSELECT6 270
%define SYS_PPOLL 271
%define SYS_UNSHARE 272
%define SYS_SET_ROBUST_LIST 273
%define SYS_GET_ROBUST_LIST 274
%define SYS_SPLICE 275
%define SYS_TEE 276
%define SYS_SYNC_FILE_RANGE 277
%define SYS_VMSPLICE 278
%define SYS_MOVE_PAGES 279
%define SYS_UTIMENSAT 280
%define SYS_EPOLL_PWAIT 281
%define SYS_SIGNALFD 282
%define SYS_TIMERFD_CREATE 283
%define SYS_EVENTFD 284
%define SYS_FALLOCATE 285
%define SYS_TIMERFD_SETTIME 286
%define SYS_TIMERFD_GETTIME 287
%define SYS_ACCEPT4 288
%define SYS_SIGNALFD4 289
%define SYS_EVENTFD2 290
%define SYS_EPOLL_CREATE1 291
%define SYS_DUP3 292
%define SYS_PIPE2 293
%define SYS_INOTIFY_INIT1 294
%define SYS_PREADV 295
%define SYS_PWRITEV 296
%define SYS_RT_TGSIGQUEUEINFO 297
%define SYS_PERF_EVENT_OPEN 298
%define SYS_RECVMMSG 299
%define SYS_FANOTIFY_INIT 300
%define SYS_FANOTIFY_MARK 301
%define SYS_PRLIMIT64 302
%define SYS_NAME_TO_HANDLE_AT 303
%define SYS_OPEN_BY_HANDLE_AT 304
%define SYS_CLOCK_ADJTIME 305
%define SYS_SYNCFS 306
%define SYS_SENDMMSG 307
%define SYS_SETNS 308
%define SYS_GETCPU 309
%define SYS_PROCESS_VM_READV 310
%define SYS_PROCESS_VM_WRITEV 311
%define SYS_KCMP 312
%define SYS_FINIT_MODULE 313

%else

%define SYS_EXIT 0x01
%define SYS_FORK 0x02
%define SYS_READ 0x03
%define SYS_WRITE 0x04
%define SYS_OPEN 0x05
%define SYS_CLOSE 0x06
%define SYS_WAITPID 0x07
%define SYS_EXECVE 0x0b
%define SYS_PTRACE 0x1a
%define SYS_KILL 0x25
%define SYS_DUP2 0x3f
%define SYS_GETDENTS 0x8d 
%define SYS_PRCTL 0xac
%define SYS_GETUID 0xc7
%define SYS_SOCKET 0x167
%define SYS_BIND 0x169
%define SYS_LISTEN 0x16b
%define SYS_ACCEPT4 0x16c
%endif

; LZSS

%define POSITION_BITS 11  
%define LENGTH_BITS  4 
%define MIN_LENGTH   0x2
%define WINDOW_LENGTH (1 << POSITION_BITS)
%define LOOKAHEAD_LENGTH ((1 << LENGTH_BITS) + 1)
