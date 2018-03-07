.nds
.relativeinclude on
.erroronwarning on

; This patch fixes a bug in PoR where the map will consider the player to be in the next room over if they are on the very edge of the screen.
; This bug causes the suspend glitch, and the glitch in room randomizer where walking through a door will reveal the map tile of the room you would have normally entered in the vanilla game without room randomizer.

@Overlay119Start equ 0x02308EC0
@FreeSpace equ @Overlay119Start + 0x60

.open "ftc/arm9.bin", 02000000h

.org 0x0202E5F8
  push r4-r10,r14
  
  ldr r4, =020FCAB0h
  ldr r5, =020FCC10h
  ldr r6, =02111778h
  ldrh r7, [r6] ; Read room's x pos from 02111778
  ldrh r8, [r6, 2h] ; Read room's y pos from 0211177A
  
  ldr r0, [r4] ; Read player 1's x pos from 020FCAB0
  bl @ClampXPosToRoomWidth
  add r0, r0, r7 ; Add player 1's x to room's x
  strh r0, [r6, 4h] ; Store player 1's x on map to 0211177C
  
  ldr r0, [r5] ; Read player 2's x pos from 020FCC10
  bl @ClampXPosToRoomWidth
  add r0, r0, r7 ; Add player 2's x to room's x
  strh r0, [r6, 6h] ; Store player 2's x on map to 0211177E
  
  ldr r0, [r4, 4h] ; Read player 1's y pos from 020FCAB4
  bl @ClampYPosToRoomHeight
  add r0, r0, r8 ; Add player 1's y to room's y
  strh r0, [r6, 8h] ; Store player 1's y on map to 02111780
  
  ldr r0, [r5, 4h] ; Read player 2's y pos from 020FCC14
  bl @ClampYPosToRoomHeight
  add r0, r0, r8 ; Add player 2's y to room's y
  strh r0, [r6, 0Ah] ; Store player 2's y on map to 02111782
  
  
  ; The rewritten first half of the function now correctly updates the players' positions on the map.
  ; But the second half of the function which updates the tile being explored needs certain values to be in certain registers to work correctly.
  ; So we initialize those registers here.
  ldrb r4, [r6, 0Dh] ; r4 has current area index read from 02111785
  mov r0, r4
  bl 02030570h ; MapGetExploredTileListForArea
  mov r5, r0 ; r5 has current area's explored tile list pointer
  mov r0, r4 ; ; r0 has current area index
  ldr r7, =020CA580h ; PointerToGameObject
  ldr r14, =1B50Ch
  ldr r6, =1B510h
  
  
  b 0202E6CCh
  .pool

.close

.open "ftc/overlay9_119", @Overlay119Start

.org @FreeSpace
@ClampXPosToRoomWidth:
  mov r0, r0, asr 14h ; Divide X by 0x100000 subpixels to get X in screens.
  cmp r0, 0h
  movlt r0, 0h ; X = 0 if X < 0
  ldr r2, =02112458h
  ldr r2, [r2]
  ldrb r2, [r2] ; Load the room's width from the collision layer (the first layer)
  sub r2, r2, 1h
  cmp r0, r2
  movgt r0, r2 ; X = room_width-1 if X > room_width-1
  bx r14
@ClampYPosToRoomHeight:
  ldr r12,=2AAAAAABh
  smull r12,r0,r12,r0 ; Divide Y in subpixels by 6
  mov r0, r0, asr 11h ; Further divide Y by 0x20000, divided by a total of 0xC0000 to get Y in screens
  cmp r0, 0h
  movlt r0, 0h ; Y = 0 if Y < 0
  ldr r2, =02112458h
  ldr r2, [r2]
  ldrb r2, [r2, 1h] ; Load the room's height from the collision layer (the first layer)
  sub r2, r2, 1h
  cmp r0, r2
  movgt r0, r2 ; Y = room_height-1 if Y > room_height-1
  bx r14
  .pool

.close
