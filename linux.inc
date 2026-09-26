; ------------------------------------------------------------
; linux.inc
;
; Named constants for the Linux x86-64 syscall ABI and the
; ioctl/fcntl/termios values this project's library uses.
; %include this file instead of writing raw numbers, so every
; module refers to the same names.
;
; Note: %include is a preprocessor directive. It pastes this
; file's text in place at assembly time — it is not a linker
; symbol like extern/global, so it has no effect on the final
; binary's size, and each file that includes it gets its own
; copy of these definitions.
; ------------------------------------------------------------

; Syscall numbers (x86-64 Linux ABI)
%define SYS_READ      0
%define SYS_WRITE     1
%define SYS_OPEN      2
%define SYS_CLOSE     3
%define SYS_IOCTL     16
%define SYS_NANOSLEEP 35
%define SYS_EXIT      60
%define SYS_FCNTL     72

; Standard file descriptors
%define STDIN  0
%define STDOUT 1
%define STDERR 2

; ioctl requests used to read/write terminal settings
%define TCGETS 0x5401
%define TCSETS 0x5402

; termios c_lflag bits
%define ICANON 2
%define ECHO   8

; fcntl commands and flags
%define F_GETFL    3
%define F_SETFL    4
%define O_NONBLOCK 2048

; ASCII control character (starts an ANSI escape sequence)
%define ESC 27

; errno
EAGAIN equ 11
