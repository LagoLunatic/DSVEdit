.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_25", 022D7900h

; In Jonathan mode, start the game as player 2 (Charlotte) instead of player 1.
.org 0x022D90F0
  strb r3,[r1,0CE7h]
  nop

.close

.open "ftc/overlay9_78", 022E8820h

; Make the drawbridge be down by default in all modes.
.org 0x022E8880
  mov r1, 1h

.close

; TODO: Certain cutscenes (like the one where you enter the first portrait) will forcibly switch you to Jonathan.
