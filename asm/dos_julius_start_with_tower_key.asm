.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_0", 0219E3E0h

; This patch starts the player with the Tower Key in Julius mode.
; This is so the player doesn't get softlocked by the randomizer in Julius mode.

.org 0x021F6280
  ; Give all 5 magic seals (simplified version of the original code that was here)
  mov r4, 1Fh
  ldr r0, =020F7254h
  strb r4, [r0]
  ; Then give Tower Key
  mov r0, 2h
  mov r1, 39h
  bl 021E7870h ; GiveItem
  b 021F62A8h ; Jump to after the constant pool
  .pool

.close
