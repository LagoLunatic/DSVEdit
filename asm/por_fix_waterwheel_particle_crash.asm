.nds
.relativeinclude on
.erroronwarning on

; The water splashing particles at the bottom of the waterwheel room in the Tower of Death have a bug in vanilla where they don't check if another particle entity is null or not.
; This bug causes the game to crash if all particle type entity slots (81-EF) are used up.

@Overlay119Start equ 0x02308EC0
@FreeSpace equ @Overlay119Start + 0x4AC

.open "ftc/overlay9_86", 022E8820h

.org 0x022EAE08
  b @CheckWaterParticleIsNull

.close


.open "ftc/overlay9_119", @Overlay119Start

.org @FreeSpace
@CheckWaterParticleIsNull:
  ; If the particle is null, skip the code that uses it.
  cmp r4, 0h
  beq 0x022EAE40
  
  ; Otherwise continue with the normal code.
  add r3, r4, 30h ; Replace the line we overwrote to jump here
  b 0x022EAE0C

.close
