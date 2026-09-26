extern state_init
extern state_debug_print

section .text
  global _start

_start:
  call state_init
  call state_debug_print

  ; Exit the program
  mov rax, 60         ; sys_exit
  xor rdi, rdi        ; status 0
  syscall
