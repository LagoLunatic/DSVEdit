.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_22", 02223E00h

; Shanoa mode: Makes all areas except Dracula's castle be unlocked from the start.
.org 0x0223B7F4 ; Code that would normally set Ecclesia as the default unlocked area.
  ldr r14, =021003CCh
  ldr r0, [r14]
  mvn r1, 0h
  orr r0, r0, r1, lsl 2h ; Set all bits except the 2 lowest bits (which are for Dracula's Castle).
  stmia [r14]!, r0, r1
  b 0223B840h
  .pool

; Albus mode: Makes all areas be unlocked from the start.
.org 0x0223B810 ; Code that would normally set Wygol and Monastery as the default unlocked areas.
  ldr r14, =021003CCh
  mvn r1, 0h ; Set all bits.
  str r1, [r14]
  str r1, [r14, 4h]
  .pool
  nop
  nop
  nop
  nop
  nop
  nop
  nop

.close

.include "ooe_nonlinear_events.asm"
