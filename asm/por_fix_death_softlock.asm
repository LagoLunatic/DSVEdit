.nds
.relativeinclude on
.erroronwarning on

; Fixes a vanilla bug where skipping the cutscene after you kill Death too quickly will prevent Death's boss death flag from being set.
; As a result of that bug the boss doors would relock after you exit the room, though Death himself wouldn't ever be fightable again.

.open "ftc/overlay9_64", 022D7900h

.org 0x022D8B18
  nop

.close
