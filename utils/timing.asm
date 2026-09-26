; ------------------------------------------------------------
; sleep_tick
;
; Pauses execution for one game "tick" using nanosleep.
;
; Input:
;   none
;
; Output:
;   none
;
; Clobbers:
;   none (RAX, RDI, RSI are used internally but restored)
;
; Notes:
;   The tick length lives in this file's own .data section
;   (tick_length: tv_sec, tv_nsec). Change tv_sec/tv_nsec here
;   to speed up or slow down the game.
; ------------------------------------------------------------

global sleep_tick

section .data
    tick_length:
        dq 0                 ; tv_sec
        dq 500000000         ; tv_nsec (0.5 seconds)

section .text

sleep_tick:
    push rax
    push rdi
    push rsi
    mov rax, 35              ; sys_nanosleep
    mov rdi, tick_length
    mov rsi, 0
    syscall
    pop rsi
    pop rdi
    pop rax
    ret
