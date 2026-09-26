; ------------------------------------------------------------
; input_raw_enable / input_raw_disable
;
; Switch stdin (fd 0) between "normal" terminal mode and "raw"
; mode: canonical mode off (no waiting for Enter), echo off
; (typed characters are not echoed back), and non-blocking reads
; on (read() returns immediately even with no key pressed).
;
; Input:
;   none (both procedures)
;
; Output:
;   none (both procedures)
;
; Clobbers:
;   none (RAX, RDI, RSI, RDX are used internally but restored)
;
; Notes:
;   input_raw_disable MUST run before the program exits, on
;   every exit path — otherwise the user's terminal is left in
;   raw mode after the program ends.
; ------------------------------------------------------------

%include "linux.inc"

global input_raw_enable
global input_raw_disable
global input_read_key

section .data
    icanon_echo equ ICANON + ECHO

section .bss
    termios_buf resb 64
    saved_lflag resb 4
    saved_flags resb 4
    input_key_buf resb 1

section .text

input_raw_enable:
    push rax
    push rdi
    push rsi
    push rdx

    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCGETS
    mov rdx, termios_buf
    syscall

    mov eax, [termios_buf + 12]
    mov [saved_lflag], eax
    and eax, ~icanon_echo
    mov [termios_buf + 12], eax

    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCSETS
    mov rdx, termios_buf
    syscall

    mov rax, SYS_FCNTL
    mov rdi, STDIN
    mov rsi, F_GETFL
    mov rdx, 0
    syscall
    mov [saved_flags], eax

    mov edx, eax
    or edx, O_NONBLOCK
    mov rax, SYS_FCNTL
    mov rdi, STDIN
    mov rsi, F_SETFL
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

input_raw_disable:
    push rax
    push rdi
    push rsi
    push rdx

    mov edx, [saved_flags]
    mov rax, SYS_FCNTL
    mov rdi, STDIN
    mov rsi, F_SETFL
    syscall

    mov eax, [saved_lflag]
    mov [termios_buf + 12], eax
    mov rax, SYS_IOCTL
    mov rdi, STDIN
    mov rsi, TCSETS
    mov rdx, termios_buf
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

;-----------------------------------------------------------
; input_read_key
;
; Output:
;   rax = 0       -> no key
;   rax = ASCII   -> key was read
;-----------------------------------------------------------

input_read_key:
    mov rax, SYS_READ
    mov rdi, STDIN
    lea rsi, [input_key_buf]
    mov rdx, 1
    syscall

    cmp rax, 1
    je .got_key

    ; EAGAIN / any other read error -> no key
    xor eax, eax
    ret

.got_key:
    movzx eax, byte [input_key_buf]
    ret
