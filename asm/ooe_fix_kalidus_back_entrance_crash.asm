.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_19", 021FFFC0h

; Fixes a bug where beating Lighthouse without ever visiting Kalidus Channel and then trying to enter Kalidus Channel would crash the game.
; The bug is because the code expects you to have explored at least one of the other entrances in Kalidus Channel, but by skipping it the map is completely blank.
.org 0x0221D814 ; Normally this would set the flag for the hand to point to the new entrance in Kalidus Channel, but we can just overwrite this, the hand isn't important.
  mov r0, 6h
  mov r1, 0h
  mov r2, 0h
  bl 02046144h ; Calls a function to set the first entrance room in the Kalidus Channel map (area 6, sector 0, room 0, aka the upper left room) to explored.

.close
