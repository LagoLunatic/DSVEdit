.nds
.relativeinclude on
.erroronwarning on

; This patch fixes the bug where the common enemy version of The Creature sets his boss death flag.

.open "ftc/overlay9_60", 022D7900h

.org 0x022D7D14
  ; Check if Var A is 0 (common enemy/boss rush version) and skip setting the boss death flag if so.
  ; This code already existed around here in vanilla, we're just moving it up a few lines to before setting the boss death flag instead of after.
  ldrh r1, [r1, 3Ch]
  cmp r1, 0h
  beq 0x022D7D30
  
  ; Then set the boss death flag.
  ldr r2, [r0, 76Ch]
  orr r2, r2, 200h
  str r2, [r0, 76Ch]

.close
