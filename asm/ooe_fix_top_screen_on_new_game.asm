.nds
.relativeinclude on
.erroronwarning on

; This patch changes the top screen shown when you start a new game to be the map screen instead of a black screen.

.open "ftc/overlay9_20", 021FFFC0h

.org 0x02214F68 ; Code run when starting a new game that specifies what top screen to set.
  mov r0, 5h ; Change to top screen 5, the normal map.

.close
