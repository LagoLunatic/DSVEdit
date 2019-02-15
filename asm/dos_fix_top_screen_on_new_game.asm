.nds
.relativeinclude on
.erroronwarning on

; This patch changes the top screen when you start a new game to be the map screen instead of the castle+moon used on the title screen.

.open "ftc/overlay9_0", 0219E3E0h

.org 0x021F62D4 ; At the end of NewGameGiveStartingItems, right as the return starts
  ; The return statement takes up 2 lines of code ("pop r4, r14" followed by "bx r14").
  ; We condense the return statement into just 1 line ("pop r4, r15").
  ; Then we can sneak in an extra function call before the return.
  bl 0203B998h ; SetTopScreenToLastUsedIngameTopScreen
  pop r4, r15

.close
