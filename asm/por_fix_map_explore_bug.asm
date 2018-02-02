.nds
.relativeinclude on
.erroronwarning on

; This patch fixes a bug in PoR where the map will consider the player to be in the next room over if they are on the very edge of the screen.
; This bug causes the suspend glitch, and the glitch in room randomizer where walking through a door will reveal the map tile of the room you would have normally entered in the vanilla game without room randomizer.

@Overlay119Start equ 0x02308EC0
@FreeSpace equ @Overlay119Start + 0x60

.open "ftc/arm9.bin", 02000000h

.org 0x0202E630
  mov r0, r2, asr 14h ; Divide subpixels X pos by 0x100000 to get X pos in screens
  b @ClampXPosToRoomWidth
  add r0, r3, r0 ; Add X pos within the room in screens (now clamped) to the room's X pos on the map

.org 0x0202E660
  mov r0, r2, asr 11h ; r2 has Y pos in subpixels/6, now divide by 0x20000 to get Y pos in screens
  b @ClampYPosToRoomHeight
  mov r2, r0 ; Move Y pos within the room in screens (now clamped) back to r2 where it will be added to the room's Y pos on the map

.close

.open "ftc/overlay9_119", @Overlay119Start

.org @FreeSpace
@ClampXPosToRoomWidth:
  push r1, r3
  cmp r0, 0h
  movlt r0, 0h ; X = 0 if X < 0
  ldr r2, =02112458h
  ldr r2, [r2]
  ldrb r2, [r2] ; Load the room's width from the collision layer (the first layer)
  sub r2, r2, 1h
  cmp r0, r2
  movgt r0, r2 ; X = room_width-1 if X > room_width-1
  pop r1, r3
  b 202E638h ; Return
@ClampYPosToRoomHeight:
  push r1, r3
  cmp r0, 0h
  movlt r0, 0h ; Y = 0 if Y < 0
  ldr r2, =02112458h
  ldr r2, [r2]
  ldrb r2, [r2, 1h] ; Load the room's height from the collision layer (the first layer)
  sub r2, r2, 1h
  cmp r0, r2
  movgt r0, r2 ; Y = room_height-1 if Y > room_height-1
  pop r1, r3
  b 202E668h ; Return
  .pool

.close
