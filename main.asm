%include "linux.inc"

extern input_raw_enable
extern input_raw_disable
extern input_read_key

extern sleep_tick

extern state_init
extern state_debug_print
extern state_set_direction
extern state_update
extern state_check_food
extern state_check_collision
extern game_over
extern draw_cursor_hide
extern draw_cursor_show

extern draw_frame
extern draw_snake
extern draw_food

section .text
    global _start

_start:
    call input_raw_enable
    call draw_cursor_hide
    call state_init

.loop:

    ;-------------------------------------------------------
    ; Read keyboard
    ;-------------------------------------------------------

    call input_read_key

    ; No key?
    test rax, rax
    jz .update

    ;-------------------------------------------------------
    ; Check for quit
    ;-------------------------------------------------------

    cmp al, 'q'
    je .quit

    ;-------------------------------------------------------
    ; WASD -> direction
    ;-------------------------------------------------------

    cmp al, 'w'
    je .up

    cmp al, 'a'
    je .left

    cmp al, 's'
    je .down

    cmp al, 'd'
    je .right

    ; Some other key -> ignore
    jmp .update


.up:
    mov dil, 0
    mov sil, -1
    call state_set_direction
    jmp .update


.left:
    mov dil, -1
    mov sil, 0
    call state_set_direction
    jmp .update


.down:
    mov dil, 0
    mov sil, 1
    call state_set_direction
    jmp .update


.right:
    mov dil, 1
    mov sil, 0
    call state_set_direction


.update:

    ;-------------------------------------------------------
    ; Update game state
    ;-------------------------------------------------------

    call state_update
    call state_check_collision
    cmp byte [game_over], 1
    je .game_over
    call state_check_food

    ;-------------------------------------------------------
    ; Draw
    ;-------------------------------------------------------

    call draw_frame
    call draw_snake
    call draw_food

    ;-------------------------------------------------------
    ; Wait for next tick
    ;-------------------------------------------------------

    call sleep_tick

    jmp .loop

.game_over:

    call draw_frame
    call draw_snake
    call draw_food
    jmp .quit

.quit:

    call input_raw_disable
    call draw_cursor_show

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
