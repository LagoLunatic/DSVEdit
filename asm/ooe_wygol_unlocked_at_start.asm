.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_22", 02223E00h

; Shanoa mode: Makes Ecclesia and Wygol be unlocked from the start.
.org 0x0223B7F4 ; Code that would normally set Ecclesia as the default unlocked area.
  ldr r14, =021003CCh
  ldr r0, [r14]
  mov r1, 0x0000003C ; Sets both bits for Ecclesia and Wygol
  orr r0, r0, r1
  str r0, [r14]
  b 0223B840h
  .pool

.close
