%include "linux.inc"

extern input_raw_enable
extern input_raw_disable
extern sleep_tick

extern state_init
extern state_debug_print
extern state_update
extern draw_frame
extern draw_snake
extern draw_food

section .text
  global _start

_start:
  call input_raw_enable
  call state_init
  mov r12, 10

.loop:
  call state_update
  call draw_frame
  call draw_snake
  call draw_food
  call sleep_tick
  dec r12
  jnz .loop

  call input_raw_disable

  ; Exit the program
  mov rax, SYS_EXIT
  xor rdi, rdi        ; status 0
  syscall
