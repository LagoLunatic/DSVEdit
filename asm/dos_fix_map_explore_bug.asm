.nds
.relativeinclude on
.erroronwarning on

; This patch fixes a bug in DoS where the map will consider the player to be in the next room over if they are on the very edge of the screen.
; This bug causes the glitch in the room randomizer (or sliding puzzle in the vanilla game) where walking through a door will reveal the map tile of the room you would have normally entered without room randomizer/sliding puzzle.

@Overlay41Start equ 0x02308920
@FreeSpace equ @Overlay41Start + filesize("ftc/overlay9_41")

.open "ftc/arm9.bin", 02000000h

.org 0x020226B4
  b @ClampXPosToRoomWidth
.org 0x020226C4
  b @ClampYPosToRoomHeight

.close

.open "ftc/overlay9_41", @Overlay41Start

.org @FreeSpace
@ClampXPosToRoomWidth:
  mov r3, r1, asr 14h ; Divide subpixels X pos by 0x100000 to get X pos in screens
  cmp r3, 0h
  movlt r3, 0h ; X = 0 if X < 0
  ldr r1, =020F75A8h
  ldr r1, [r1]
  ldrb r1, [r1] ; Load the room's width from the collision layer (the first layer)
  sub r1, r1, 1h
  cmp r3, r1
  movgt r3, r1 ; X = room_width-1 if X > room_width-1
  add r3, r3, r5 ; Add the room's X pos to the player's X pos within the room in screens (now clamped).
  b 20226B8h ; Return
@ClampYPosToRoomHeight:
  cmp r7, 0h
  movlt r7, 0h ; Y = 0 if Y < 0
  ldr r1, =020F75A8h
  ldr r1, [r1]
  ldrb r1, [r1, 1h] ; Load the room's height from the collision layer (the first layer)
  sub r1, r1, 1h
  cmp r7, r1
  movgt r7, r1 ; Y = room_height-1 if Y > room_height-1
  add r1, r7, r2 ; Add the room's Y pos to the player's Y pos within the room in screens (now clamped).
  b 20226C8h ; Return
  .pool

.close
