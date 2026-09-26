
; ------------------------------------------------------------
; strlen
;
; Computes the length of a null-terminated string.
;
; Input:
;   RSI = address of the string
;
; Output:
;   RDX = length of the string (not counting the null byte)
;
; Clobbers:
;   none (RAX and RSI are used internally but restored)
; ------------------------------------------------------------
 
global strlen
global int_to_string
 
section .text
 
strlen:
    push rax
    push rsi
    xor rdx, rdx
.loop:
    cmp byte [rsi + rdx], 0
    je .done
    inc rdx
    jmp .loop
.done:
    pop rsi
    pop rax
    ret
 
; ------------------------------------------------------------
; int_to_string
;
; Converts a signed 64-bit integer into a decimal string,
; writing it backwards from the end of a caller-supplied buffer.
;
; Input:
;   RAX = signed 64-bit integer
;   RSI = address of the LAST byte of the buffer
;
; Output:
;   RSI = address of the first character of the resulting string
;   RDX = length of the string (not counting the null terminator)
;
; Clobbers:
;   R8, R9, R10
;
; Notes:
;   The buffer must be at least 21 bytes long:
;     - 19 characters for the absolute value of INT64_MIN
;     - 1 character for '-'
;     - 1 character for the null terminator
;   Negation uses two's complement arithmetic, which correctly
;   handles INT64_MIN as a special case: negating it overflows
;   back to the same bit pattern, which is exactly its unsigned
;   magnitude, so the unsigned division below still works.
;
; Example:
;   RAX = -12345
;   RSI = buffer + 20
;   -> RSI points to "-12345", RDX = 6
; ------------------------------------------------------------
 
int_to_string:
    xor r8d, r8d
    test rax, rax
    jns .positive
 
    mov r8b, 1
 
.positive:
    mov byte [rsi], 0
 
    test rax, rax
    jnz .convert
 
    dec rsi
    mov byte [rsi], '0'
    mov edx, 1
    ret
 
.convert:
    test r8b, r8b
    jz .digits
 
    neg rax
 
.digits:
    xor r9d, r9d
    mov r10d, 10
 
.next_digit:
    dec rsi
 
    xor edx, edx
    div r10
 
    add dl, '0'
    mov [rsi], dl
 
    inc r9
 
    test rax, rax
    jnz .next_digit
 
    test r8b, r8b
    jz .done
 
    dec rsi
    mov byte [rsi], '-'
    inc r9
 
.done:
    mov rdx, r9
    ret
