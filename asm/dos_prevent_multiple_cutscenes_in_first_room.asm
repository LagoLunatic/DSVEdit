.nds
.relativeinclude on
.erroronwarning on

; This patch fixes issues that could happen in the first room of the castle if the player got one of the bad endings before seeing the cutscene with Hammer in that first room.
; The cutscene with Hammer would play at the same time as the bad ending cutscene, and could allow skipping the cutscene to get out of the room, escaping from the bad ending.

@Overlay41Start equ 0x02308920
@FreeSpace equ @Overlay41Start + 0x1DC

.open "ftc/overlay9_0", 0219E3E0h

.org 0x021C84DC ; In Object5ECreate (cutscene in the first room of the castle with Hammer)
  bne @CheckInBadEnding

.close

.open "ftc/overlay9_41", @Overlay41Start

.org @FreeSpace
@CheckInBadEnding:
  ldr r1, =020F7188h ; Bitfield of event flags
  ldr r1, [r1]
  ands r1, r1, 24000h ; Check the two bad ending flags
  beq 0x021C84F4 ; If neither are set, continue on with this event code
  b 0x021C84E0 ; Otherwise, delete this event
  .pool

.close
