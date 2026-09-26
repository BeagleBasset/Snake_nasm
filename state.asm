;-----------------------------------------------------------
; state.asm
;
; Handle the state of the game, including player position,
; score, and other relevant data.
;-----------------------------------------------------------

; externs
extern print
extern int_to_string

section .data
    %include "config.inc"

; Debugging strings
    dbg_head     db "Head: ("
    dbg_head_len equ $ - dbg_head

    dbg_comma    db ","
    dbg_comma_len equ $ - dbg_comma

    dbg_len      db ") Length: "
    dbg_len_len  equ $ - dbg_len

    dbg_dir      db " Dir: ("
    dbg_dir_len  equ $ - dbg_dir

    dbg_food     db ") Food: ("
    dbg_food_len equ $ - dbg_food

    dbg_score    db ") Score: "
    dbg_score_len equ $ - dbg_score

    dbg_newline  db 10

section .bss
    snake_x      resb MAX_LENGTH   ; snake_x[0] = head
    snake_y      resb MAX_LENGTH
    snake_length resb 1
    dir_x        resb 1      ; -1, 0 or 1
    dir_y        resb 1
    food_x       resb 1
    food_y       resb 1
    score        resb 1
    game_over    resb 1

    int_buffer   resb 32     ; buffer for int_to_string

section .text
    global state_init
    global state_debug_print

;-----------------------------------------------------------
; state_init
;-----------------------------------------------------------

state_init:
    mov byte [snake_length], 3
    mov byte [dir_x], 1
    mov byte [dir_y], 0
    mov byte [snake_x], 15
    mov byte [snake_y], 7
    mov byte [food_x], 10
    mov byte [food_y], 5
    mov byte [score], 0
    mov byte [game_over], 0
    ret

;-----------------------------------------------------------
; state_debug_print
;
; Prints:
;
; Head: (15,7) Length: 3 Dir: (1,0) Food: (10,5) Score: 0
;-----------------------------------------------------------

state_debug_print:
; Head
    mov rdi, 1
    mov rsi, dbg_head
    mov rdx, dbg_head_len
    call print

    movzx eax, byte [snake_x]
    lea rsi, [int_buffer + 31]  ; point to the end of the buffer
    call int_to_string

    mov rdi, 1
    call print

    mov rdi, 1
    mov rsi, dbg_comma
    mov rdx, dbg_comma_len
    call print

    movzx eax, byte [snake_y]
    lea rsi, [int_buffer + 31]  ; point to the end of the buffer
    call int_to_string

    mov rdi, 1
    call print

; Snake length
    mov rdi, 1
    mov rsi, dbg_len
    mov rdx, dbg_len_len
    call print

    movzx eax, byte [snake_length]
    lea rsi, [int_buffer + 31]  ; point to the end of the buffer
    call int_to_string

    mov rdi, 1
    call print

; Direction
    mov rdi, 1
    mov rsi, dbg_dir
    mov rdx, dbg_dir_len
    call print

    movzx eax, byte [dir_x]
    lea rsi, [int_buffer + 31]  ; point to the end of the buffer
    call int_to_string

    mov rdi, 1
    call print

    mov rdi, 1
    mov rsi, dbg_comma
    mov rdx, dbg_comma_len
    call print

    movzx eax, byte [dir_y]
    lea rsi, [int_buffer + 31]  ; point to the end of the buffer
    call int_to_string

    mov rdi, 1
    call print

; Food Position
    mov rdi, 1
    mov rsi, dbg_food
    mov rdx, dbg_food_len
    call print

    movzx eax, byte [food_x]
    lea rsi, [int_buffer + 31]  ; point to the end of the buffer
    call int_to_string

    mov rdi, 1
    call print

    mov rdi, 1
    mov rsi, dbg_comma
    mov rdx, dbg_comma_len
    call print

    movzx eax, byte [food_y]
    lea rsi, [int_buffer + 31]  ; point to the end of the buffer
    call int_to_string

    mov rdi, 1
    call print

; Score
    mov rdi, 1
    mov rsi, dbg_score
    mov rdx, dbg_score_len
    call print

    movzx eax, byte [score]
    lea rsi, [int_buffer + 31]  ; point to the end of the buffer
    call int_to_string

    mov rdi, 1
    call print

; Newline  
    mov rdi, 1
    mov rsi, dbg_newline
    mov rdx, 1
    call print
