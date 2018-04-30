.nds
.relativeinclude on
.erroronwarning on

; This is for the enemy sprite randomizer.
; It adds a new function that works the same as LoadSpriteMultiGfx, but only takes 4 arguments like LoadSpriteSingleGfx.
; That allows us to swap calls to LoadSpriteSingleGfx out for this custom function instead.

@Overlay86Start equ 0x022EB1A0
@FreeSpace equ @Overlay86Start + 0x2C

.open "ftc/overlay9_86", @Overlay86Start

.org @FreeSpace
  push r4, r14
  sub r13, r13, 4h
  mov r4, 1h
  str r4, [r13]
  bl 0203B6D0h ; LoadSpriteMultiGfx
  add r13, r13, 4h
  pop r4, r15

.close
