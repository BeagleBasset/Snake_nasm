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

global input_raw_enable
global input_raw_disable

section .data
    tcgets      equ 0x5401
    tcsets      equ 0x5402
    icanon_echo equ 10          ; ICANON (2) + ECHO (8)
    f_getfl     equ 3
    f_setfl     equ 4
    o_nonblock  equ 2048

section .bss
    termios_buf resb 64
    saved_lflag resb 4
    saved_flags resb 4

section .text

input_raw_enable:
    push rax
    push rdi
    push rsi
    push rdx

    mov rax, 16               ; sys_ioctl
    mov rdi, 0
    mov rsi, tcgets
    mov rdx, termios_buf
    syscall

    mov eax, [termios_buf + 12]
    mov [saved_lflag], eax
    and eax, ~icanon_echo
    mov [termios_buf + 12], eax

    mov rax, 16
    mov rdi, 0
    mov rsi, tcsets
    mov rdx, termios_buf
    syscall

    mov rax, 72               ; sys_fcntl
    mov rdi, 0
    mov rsi, f_getfl
    mov rdx, 0
    syscall
    mov [saved_flags], eax

    mov edx, eax
    or edx, o_nonblock
    mov rax, 72
    mov rdi, 0
    mov rsi, f_setfl
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
    mov rax, 72
    mov rdi, 0
    mov rsi, f_setfl
    syscall

    mov eax, [saved_lflag]
    mov [termios_buf + 12], eax
    mov rax, 16
    mov rdi, 0
    mov rsi, tcsets
    mov rdx, termios_buf
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret
