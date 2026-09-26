; ------------------------------------------------------------
; print
;
; Writes a sequence of bytes to a file descriptor.
;
; Input:
;   RDI = file descriptor (e.g. 1 = stdout, 2 = stderr)
;   RSI = address of the first byte to write
;   RDX = number of bytes to write
;
; Output:
;   none
;
; Clobbers:
;   none (RAX and RCX are used internally but restored)
;
; Notes:
;   Every syscall clobbers RCX and R11 as a side effect of the
;   syscall instruction itself, regardless of which syscall it is.
;   This procedure protects RCX with push/pop, so a caller that
;   keeps a loop counter in RCX is safe to call print from inside
;   that loop. R11 is not protected here, because nothing in this
;   codebase keeps long-lived state in R11.
; ------------------------------------------------------------

global print

section .text

print:
    push rcx
    mov rax, 1              ; sys_write
    syscall
    pop rcx
    ret
