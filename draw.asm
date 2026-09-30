;-----------------------------------------------------------
; draw.asm
;
; Draw the game state to the terminal.
; This module only READS state.asm data.
;-----------------------------------------------------------

%include "linux.inc"

extern print
extern int_to_string

extern snake_x
extern snake_y
extern snake_length
extern food_x
extern food_y
extern score

section .data
    %include "config.inc"

    ; ANSI escape sequence pieces
    esc_prefix      db ESC, "["
    esc_prefix_len  equ $ - esc_prefix

    esc_semicolon   db ";"
    esc_semicolon_len equ $ - esc_semicolon

    esc_H           db "H"
    esc_H_len       equ $ - esc_H

    cursor_hide     db ESC, "[?25l"
    curosor_hide_len equ $ - cursor_hide

    cursor_show     db ESC, "[?25h"
    cursor_show_len equ $ - cursor_show

    ; Drawing characters
    border_h        db "-"
    border_v        db "|"
    border_corner   db "+"
    snake_char      db "#"
    food_char       db "*"

    ; Clear screen: ESC[2J
    clear_screen    db ESC, "[2J", ESC, "[H"
    clear_screen_len equ $ - clear_screen

    ; Game over messages
    game_over_msg   db "GAME OVER"
    game_over_msg_len equ $ - game_over_msg

    score_msg       db "Score: "
    score_msg_len   equ $ - score_msg

section .bss
    number_buffer   resb 32
    int_buffer      resb 32

section .text
    global draw_cursor_hide
    global draw_cursor_show
    global draw_frame
    global draw_snake
    global draw_food
    global draw_game_over

;-----------------------------------------------------------
; cursor_to
;
; Input:
;   rax = terminal row
;   rbx = terminal column
;
; Prints:
;   ESC[<row>;<column>H
;
; rax/rbx are 1-based terminal coordinates.
;-----------------------------------------------------------

cursor_to:
    push rbx
    push r12
    push r13

    mov r12, rax
    mov r13, rbx

    ; ESC[
    mov rdi, STDOUT
    mov rsi, esc_prefix
    mov rdx, esc_prefix_len
    call print

    ; row
    mov eax, r12d
    lea rsi, [number_buffer + 31]
    call int_to_string

    ; int_to_string returns the string pointer/length
    ; according to the project convention.
    ; Print it here.
    mov rdi, STDOUT
    call print

    ; ;
    mov rsi, esc_semicolon
    mov rdx, esc_semicolon_len
    call print

    ; column
    mov eax, r13d
    lea rsi, [number_buffer + 31]
    call int_to_string

    mov rdi, STDOUT
    call print

    ; H
    mov rsi, esc_H
    mov rdx, esc_H_len
    call print

    pop r13
    pop r12
    pop rbx
    ret


;-----------------------------------------------------------
; draw_frame
;
; Clears the screen and draws the board frame.
;
; Board cell (0,0) is terminal position (2,2).
;
; Frame:
;
;   row 1: +------------------+
;   row 2: |                  |
;   ...
;   row H+2: +------------------+
;
; The inside is BOARD_WIDTH x BOARD_HEIGHT.
;-----------------------------------------------------------

draw_frame:
    push rbx
    push r12

    ; Clear screen
    mov rsi, clear_screen
    mov rdx, clear_screen_len
    mov rdi, STDOUT
    call print

    ; ------------------------------------------------------
    ; Top-left corner: (1,1)
    ; ------------------------------------------------------

    mov rax, 1
    mov rbx, 1
    call cursor_to

    mov rsi, border_corner
    mov rdx, 1
    call print

    ; ------------------------------------------------------
    ; Top horizontal border
    ; ------------------------------------------------------

    mov r12d, BOARD_WIDTH

.top_loop:
    test r12d, r12d
    jz .top_right

    mov rsi, border_h
    mov rdx, 1
    call print

    dec r12d
    jmp .top_loop

.top_right:
    ; top-right corner = column BOARD_WIDTH + 2
    mov rax, 1
    mov ebx, BOARD_WIDTH + 2
    call cursor_to

    mov rsi, border_corner
    mov rdx, 1
    call print

    ; ------------------------------------------------------
    ; Vertical borders
    ; Rows 2 .. BOARD_HEIGHT + 1
    ; ------------------------------------------------------

    xor r12d, r12d

.side_loop:
    cmp r12d, BOARD_HEIGHT
    jae .bottom

    ; terminal row = board row + 2
    mov eax, r12d
    add eax, 2

    ; Left border
    mov ebx, 1
    call cursor_to

    mov rsi, border_v
    mov rdx, 1
    call print

    ; Right border
    mov eax, r12d
    add eax, 2

    mov ebx, BOARD_WIDTH + 2
    call cursor_to

    mov rsi, border_v
    mov rdx, 1
    call print

    inc r12d
    jmp .side_loop

    ; ------------------------------------------------------
    ; Bottom border
    ; ------------------------------------------------------

.bottom:
    ; Bottom row = BOARD_HEIGHT + 2
    mov eax, BOARD_HEIGHT + 2
    mov ebx, 1
    call cursor_to

    mov rsi, border_corner
    mov rdx, 1
    call print

    mov r12d, BOARD_WIDTH

.bottom_loop:
    test r12d, r12d
    jz .bottom_right

    mov rsi, border_h
    mov rdx, 1
    call print

    dec r12d
    jmp .bottom_loop

.bottom_right:
    mov eax, BOARD_HEIGHT + 2
    mov ebx, BOARD_WIDTH + 2
    call cursor_to

    mov rsi, border_corner
    mov rdx, 1
    call print

    pop r12
    pop rbx
    ret


;-----------------------------------------------------------
; draw_snake
;
; snake_x / snake_y contain 0-based board coordinates.
;
; Board (0,0) -> terminal (2,2)
;
; For each snake segment:
;   terminal_row = snake_y[i] + 2
;   terminal_col = snake_x[i] + 2
;-----------------------------------------------------------

draw_snake:
    push rbx
    push r12

    xor r12d, r12d

.snake_loop:
    cmp r12b, [snake_length]
    jae .done

    ; row = snake_y[i] + 2
    movzx rax, byte [snake_y + r12]
    add rax, 2

    ; col = snake_x[i] + 2
    movzx rbx, byte [snake_x + r12]
    add rbx, 2

    call cursor_to

    mov rdi, STDOUT
    mov rsi, snake_char
    mov rdx, 1
    call print

    inc r12d
    jmp .snake_loop

.done:
    pop r12
    pop rbx
    ret


;-----------------------------------------------------------
; draw_food
;
; food_x / food_y contain 0-based board coordinates.
;
; Board (0,0) -> terminal (2,2)
;-----------------------------------------------------------

draw_food:
    push rbx

    movzx rax, byte [food_y]
    add rax, 2

    movzx rbx, byte [food_x]
    add rbx, 2

    call cursor_to

    mov rdi, STDOUT
    mov rsi, food_char
    mov rdx, 1
    call print

    pop rbx
    ret

;-----------------------------------------------------------
; draw_cursor_hide
;-----------------------------------------------------------

draw_cursor_hide:
    mov rdi, STDOUT
    mov rsi, cursor_hide
    mov rdx, curosor_hide_len
    call print
    ret

;-----------------------------------------------------------
; draw_cursor_show
;-----------------------------------------------------------

draw_cursor_show:
    mov rdi, STDOUT
    mov rsi, cursor_show
    mov rdx, cursor_show_len
    call print
    ret

;-----------------------------------------------------------
; draw_game_over
;
; Draws:
;
;     GAME OVER
;     Score: N
;
; below the game board.
;-----------------------------------------------------------

draw_game_over:
    ;-------------------------------------------------------
    ; "GAME OVER"
    ; Row = BOARD_HEIGHT + 4
    ; Col = 1
    ;-------------------------------------------------------

    mov rax, BOARD_HEIGHT + 4
    mov rbx, 1
    call cursor_to

    mov rdi, STDOUT
    mov rsi, game_over_msg
    mov rdx, game_over_msg_len
    call print

    ;-------------------------------------------------------
    ; "Score: N"
    ; Row = BOARD_HEIGHT + 5
    ; Col = 1
    ;-------------------------------------------------------

    mov rax, BOARD_HEIGHT + 5
    mov rbx, 1
    call cursor_to

    mov rdi, STDOUT
    mov rsi, score_msg
    mov rdx, score_msg_len
    call print

    ; Convert score to string
    movzx eax, byte [score]

    lea rsi, [int_buffer + 31]
    call int_to_string

    ; Print converted number
    mov rdi, STDOUT
    call print

    ret
