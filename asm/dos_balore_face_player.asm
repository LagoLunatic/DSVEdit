.nds
.relativeinclude on
.erroronwarning on

; This patch makes Balore detect which side of the room the player enters from, and if it's from the left, he moves himself to face left.

.open "ftc/overlay9_23", 022FF9C0h

@Overlay41Start equ 0x02308920
@FreeSpace equ @Overlay41Start + 0x140

.org 0x022FFD44
  b @BaloreFacePlayer

.close

.open "ftc/overlay9_41", @Overlay41Start

.org @FreeSpace
@BaloreFacePlayer:
  mov r0, r5
  bl 021C3278h ; GetPlayerXPos
  cmp r0, 80000h ; X pos 0x80, halfway through the leftmost screen
  bge @BaloreFaceRight
@BaloreFaceLeft:
  mov r0, 0h ; Var A
  mov r1, 0F0000h ; X pos
  str r1, [r5, 2Ch]
  b @BaloreFacePlayerEnd
@BaloreFaceRight:
  mov r0, 1h ; Var A
  ; We don't set X pos here because we assume Balore's X pos was already properly set for facing right.
@BaloreFacePlayerEnd:
  ; Go back to Balore's normal code to set the direction he faces
  ; We make sure r0 has Var A in it - but not Balore's real Var A, just the one to check for the purposes of deciding the direction he faces.
  b 0x022FFD48

.close
