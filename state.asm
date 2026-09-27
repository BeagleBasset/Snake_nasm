;-----------------------------------------------------------
; state.asm
;
; Handle the state of the game, including player position,
; score, and other relevant data.
;-----------------------------------------------------------

%include "linux.inc"

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
    rng_state    resd 1

section .text
    global state_init
    global state_debug_print
    global state_update
    global state_set_direction
    global state_check_food
    global state_check_collision

    global snake_x
    global snake_y
    global snake_length
    global food_x
    global food_y
    global game_over

;-----------------------------------------------------------
; state_init
;-----------------------------------------------------------

state_init:
    mov dword [rng_state], 0xDEADBEEF
    mov byte [snake_length], 3
    mov byte [dir_x], 1
    mov byte [dir_y], 0
    ; Snake head
    mov byte [snake_x], 15
    mov byte [snake_y], 7
    ; Segments (body) of the snake
    ; snake[i] = head - i * dir
    mov ecx, 1
.init_snake:
    cmp cl, [snake_length]
    jae .snake_done

    ; x[i] = x[0] - i * dir_x
    movzx eax, byte [dir_x]
    imul eax, ecx
    mov bl, [snake_x]
    sub bl, al
    mov [snake_x + rcx], bl

    ; y[i] = y[0] - i * dir_y
    movzx eax, byte [dir_y]
    imul eax, ecx
    mov bl, [snake_y]
    sub bl, al
    mov [snake_y + rcx], bl

    inc ecx
    jmp .init_snake

.snake_done:
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
    mov rdi, STDOUT
    mov rsi, dbg_head
    mov rdx, dbg_head_len
    call print

    movzx eax, byte [snake_x]
    lea rsi, [int_buffer + 31]  ; point to the end of the buffer
    call int_to_string

    mov rdi, STDOUT
    call print

    mov rdi, STDOUT
    mov rsi, dbg_comma
    mov rdx, dbg_comma_len
    call print

    movzx eax, byte [snake_y]
    lea rsi, [int_buffer + 31]  ; point to the end of the buffer
    call int_to_string

    mov rdi, STDOUT
    call print

; Snake length
    mov rdi, STDOUT
    mov rsi, dbg_len
    mov rdx, dbg_len_len
    call print

    movzx eax, byte [snake_length]
    lea rsi, [int_buffer + 31]  ; point to the end of the buffer
    call int_to_string

    mov rdi, STDOUT
    call print

; Direction
    mov rdi, STDOUT
    mov rsi, dbg_dir
    mov rdx, dbg_dir_len
    call print

    movzx eax, byte [dir_x]
    lea rsi, [int_buffer + 31]  ; point to the end of the buffer
    call int_to_string

    mov rdi, STDOUT
    call print

    mov rdi, STDOUT
    mov rsi, dbg_comma
    mov rdx, dbg_comma_len
    call print

    movzx eax, byte [dir_y]
    lea rsi, [int_buffer + 31]  ; point to the end of the buffer
    call int_to_string

    mov rdi, STDOUT
    call print

; Food Position
    mov rdi, STDOUT
    mov rsi, dbg_food
    mov rdx, dbg_food_len
    call print

    movzx eax, byte [food_x]
    lea rsi, [int_buffer + 31]  ; point to the end of the buffer
    call int_to_string

    mov rdi, STDOUT
    call print

    mov rdi, STDOUT
    mov rsi, dbg_comma
    mov rdx, dbg_comma_len
    call print

    movzx eax, byte [food_y]
    lea rsi, [int_buffer + 31]  ; point to the end of the buffer
    call int_to_string

    mov rdi, STDOUT
    call print

; Score
    mov rdi, STDOUT
    mov rsi, dbg_score
    mov rdx, dbg_score_len
    call print

    movzx eax, byte [score]
    lea rsi, [int_buffer + 31]  ; point to the end of the buffer
    call int_to_string

    mov rdi, STDOUT
    call print

; Newline  
    mov rdi, STDOUT
    mov rsi, dbg_newline
    mov rdx, 1
    call print

    ret

;-----------------------------------------------------------
; state_update
;
; Move every body segment to the previous segment's old
; position, starting from the tail, then move the head.
;-----------------------------------------------------------

state_update:
    ; i = snake_length - 1
    movzx ecx, byte [snake_length]
    dec ecx

.update_body:
    cmp ecx, 0
    jle .move_head

    ; snake_x[i] = snake_x[i-1]
    movzx eax, byte [snake_x + rcx - 1]
    mov [snake_x + rcx], al

    ; snake_y[i] = snake_y[i-1]
    movzx eax, byte [snake_y + rcx - 1]
    mov [snake_y + rcx], al

    dec ecx
    jmp .update_body

.move_head:
    ; snake_x[0] += dir_x
    movzx eax, byte [dir_x]
    add byte [snake_x], al

    ; snake_y[0] += dir_y
    movzx eax, byte [dir_y]
    add byte [snake_y], al

    ret

;-----------------------------------------------------------
; state_check_collision
;
; Check whether the snake head collided with:
;   - the board boundary
;   - its own body
;
; If a collision occurs:
;   game_over = 1
;
; Input:
;   none
;
; Output:
;   none
;-----------------------------------------------------------

state_check_collision:
    ;-------------------------------------------------------
    ; Wall collision - X
    ; Coordinates are unsigned bytes.
    ; Any value >= BOARD_WIDTH means collision.
    ; This also catches 0 -> 255 when moving left.
    ;-------------------------------------------------------

    movzx eax, byte [snake_x]
    cmp eax, BOARD_WIDTH
    jae .collision

    ;-------------------------------------------------------
    ; Wall collision - Y
    ;-------------------------------------------------------

    movzx eax, byte [snake_y]
    cmp eax, BOARD_HEIGHT
    jae .collision

    ;-------------------------------------------------------
    ; Self collision
    ;
    ; Start at segment 1 because segment 0 is the head.
    ;-------------------------------------------------------

    movzx ecx, byte [snake_length]
    cmp ecx, 2
    jb .no_collision

    mov edx, 1

.check_body:
    cmp edx, ecx
    jae .no_collision

    ; Compare X
    mov al, [snake_x + rdx]
    cmp al, [snake_x]
    jne .next_segment

    ; Compare Y
    mov al, [snake_y + rdx]
    cmp al, [snake_y]
    je .collision

.next_segment:
    inc edx
    jmp .check_body

.collision:
    mov byte [game_over], 1

.no_collision:
    ret

;-----------------------------------------------------------
; state_set_direction
;
; Input:
;   DIL = requested dir_x
;   SIL = requested dir_y
;
; Values:
;   -1, 0, 1
;
; Rejects a 180 degree turn.
;-----------------------------------------------------------

state_set_direction:

    ; Check:
    ; requested_x == -current_x
    ; AND
    ; requested_y == -current_y

    movsx eax, byte [dir_x]
    neg eax
    cmp dil, al
    jne .accept

    movsx eax, byte [dir_y]
    neg eax
    cmp sil, al
    je .reject

.accept:
    mov [dir_x], dil
    mov [dir_y], sil
    ret

.reject:
    ret    

;-----------------------------------------------------------
; rng_next
;
; Advance the LCG and return a value in [0, n-1].
;
; Input:
;   edi = n
;
; Output:
;   eax = rng_state % n
;
; Clobbers:
;   EAX, ECX, EDX
;-----------------------------------------------------------

rng_next:
    mov eax, [rng_state]

    ; state = state * 1103515245 + 12345
    mov ecx, 1103515245
    imul eax, ecx
    add eax, 12345

    mov [rng_state], eax

    ; eax = state % n
    xor edx, edx
    div edi

    mov eax, edx
    ret

;-----------------------------------------------------------
; place_food
;
; Generate a new food position which is not occupied
; by any snake segment.
;
; Output:
;   food_x = random value in [0, BOARD_WIDTH-1]
;   food_y = random value in [0, BOARD_HEIGHT-1]
;
; Not global: only used inside state.asm.
;-----------------------------------------------------------

place_food:
.generate:
    ; Generate X
    mov edi, BOARD_WIDTH
    call rng_next
    mov [food_x], al

    ; Generate Y
    mov edi, BOARD_HEIGHT
    call rng_next
    mov [food_y], al

    ; Check all snake segments
    xor ecx, ecx

.check_snake:
    cmp cl, [snake_length]
    jae .free_position

    ; Check X
    mov al, [snake_x + rcx]
    cmp al, [food_x]
    jne .next_segment

    ; Check Y
    mov al, [snake_y + rcx]
    cmp al, [food_y]
    je .generate

.next_segment:
    inc ecx
    jmp .check_snake

.free_position:
    ret

;-----------------------------------------------------------
; state_check_food
;
; Check whether the snake head is on the food.
;
; If yes:
;   - grow the snake if it is not at MAX_LENGTH
;   - increase score
;   - place food at a new position
;
; Input:
;   none
;
; Output:
;   none
;-----------------------------------------------------------

state_check_food:
    ; Check X coordinate
    mov al, [snake_x]
    cmp al, [food_x]
    jne .no_food

    ; Check Y coordinate
    mov al, [snake_y]
    cmp al, [food_y]
    jne .no_food

    ; We are on the food.

    ; Grow only if snake_length < MAX_LENGTH
    movzx eax, byte [snake_length]
    cmp eax, MAX_LENGTH
    jae .no_growth

    ; new index = old snake_length
    ; copy old tail into new tail
    movzx ecx, byte [snake_length]

    mov al, [snake_x + rcx - 1]
    mov [snake_x + rcx], al

    mov al, [snake_y + rcx - 1]
    mov [snake_y + rcx], al

    inc byte [snake_length]

.no_growth:
    ; score++
    inc byte [score]

    ; Generate new food position
    call place_food

.no_food:
    ret
