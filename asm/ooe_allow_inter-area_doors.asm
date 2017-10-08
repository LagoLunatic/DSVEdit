.nds
.relativeinclude on
.erroronwarning on

; In the vanilla game, doors are not designed to take you between two different areas, and trying to use them like that results in a number of bugs, namely crashes, improperly loaded tilesets, and the wrong map being on the top screen.
; This patch fixes these bugs so that doors work correctly even when the source room and destination room are in different areas.

; Incomplete - This patch still causes crashes and incorrectly loaded tilesets in many circumstances.

@Overlay86Start equ 0x0234C200 ; Where the free space overlay is loaded in RAM.
@FreeSpace equ 0x0234C200 ; This should be set to a location in the free space overlay that is unused. If you've already used the default location in your own hack, just change this value to somewhere free.

.open "ftc/arm9.bin", 02000000h

; Bug 1: The code that loads the sector overlay for the destination sector assumes that the current area index is also the destination area index.
; Fix: Simply load the area index from the stack, because an earlier call to GetAreaSectorRoomIndexesByRoomPointer already determined the correct area index, and we simply need to use it.
.org 0x02038E10
  ldr r0, [r13, 0Ch]



; Bug 2: The transition room's asynchronous tileset loading code assumes that the current area index is also the destination area index.
; Fix: Similar to the above, GetAreaSectorRoomIndexesByRoomPointer was just called, so we can use the area index on the stack again.
;   But in this case, there's a key difference: that function was called twice, first for the door on the left of the transition room, then for the door on the right.
;   The original code preserves the sector indexes of both calls, but only preserves the area index of the right call, so even if we use this area index it will only fix the bug when going right, not left.
;   So we must modify the code to preserve both area indexes as well as both sector indexes, and then load the proper one depending on whether the player is going left or right.
; First, make more room on the stack for an extra area index (0x10 -> 0x14 bytes)
.org 0x0203931C
  sub r13, r13, 14h 
.org 0x02039364
  addeq r13, r13, 14h
.org 0x02039400
  addeq r13, r13, 14h
.org 0x02039438
  add r13, r13, 14h
; Next we need to push where it stores the sector and room indexes over by 4 bytes to make room for the second area index right after the first area index.
.org 0x0203939C
  add r6, r13, 8h ; Push room index over (4 -> 8 bytes)
.org 0x02039370
  add r9, r13, 0Ch ; Push sector index over (8 -> 0xC bytes)
.org 0x020393F0
  add r0, r13, 0Ch ; Push where it reads the sector index over to match where it actually is now (8 -> 0xC bytes)
; Now we make the left and right doors store to different spots on the stack.
.org 0x020393A4
  add r1, r7, r8, lsl 2h ; r8 is 0 for the left door, and 1 for the right door. So the left door's area index gets stored at offset 0, the right door's at offset 4.
.org 0x020393DC
  ; These 4 lines of code here run if the doors are swapped (door 00 is on the right, door 01 is on the left).
  ; What this code originally did is swap the two sector indexes in the stack so things still load right even if the level designer swapped the doors.
  ; What we need to do is update the offsets when swapping sector indexes (8 and 0xC -> 0xC and 0x10), and also add new code to swap the area indexes as well. So we go to free space to do all this (see below), and nop out the other 3 lines.
  b @SwapLeftAndRightSectorAreaIndexes
  nop
  nop
  nop
; Then the code checks if the source and destination sector indexes are the same, and if so, it returns from the function without loading the tileset.
; But even if the sector indexes are the same, if the area indexes are different, we still need it to load the tileset.
; So we go to free space if the sector indexes are the same and check the area index as well (see below).
.org 0x02039400
  beq @CheckAreaIndexIsDifferent
  nop
  nop
; But the transition rooms don't keep track of the currently loaded tileset's area index, so we need to store the area index inside the same word as the sector index is stored (the lower halfword as the sector index, the upper halfword as the area index).
.org 0x02039A84
  b @StoreLoadedSectorAreaIndexes
.org 0x020393F8
  ldrsh r12, [r4, 8h]
.org 0x020394EC
  nop ; Get rid of the initial sector index value set when the player loads in via a save. It's not necessary for it to work and just complicates things.
; And finally, we change the line of code that reads the current area index to read one of the area indexes from the stack.
.org 0x02039410
  ldr r0, [r13, r5, lsl 2h] ; r5 is 0 if the player is trying to enter the left door, 1 if trying to enter the right door.



; Bug 3: If the player moves through a transition room fast enough that the asynchronous tileset loading didn't get the chance to fully load the tilesets, the game logic pauses when they touch the door so it synchronously loads all the remaining tileset data instead. This synchronous code also assumes the area index of the destination room is the same as the current area index.
; Fix: The asynchronous transition room code stored what sector and area it was loading (sector index at 020ECA9C, area index at 020ECAA8). It already uses the sector index correctly, we just need to do the same for the area index.
;   Specifically, the synchronous code indicates to the LoadTilesetsForSector function that it should use the sector index at 020ECA9C by passing -1 as the sector index argument.
;   So first off, we change the synchronous code to also pass -1 as the area index to indicate that it should also use the previous area index.
.org 0x02038D1C
  mvn r0, 0h ; Originally this loaded the current area index, we replace it with -1.
; Next we need to add some new code in the LoadTilesetsForSector function to check if that argument is -1. To do this we branch to free space (see below).
.org 0x02039994
  b @LoadTilesetCheckUsePreviousAreaIndex



; Bug 4: If the player has the top screen set to the map, it does not automatically update to the new area's map. The player can manually fix this by pressing select twice, but it should automatically reload.
; Fix: Add some new code in free space to check if we should reload the map, and then do it if so (see below).
.org 0x02038E14
  b @CheckReloadTopScreenMap

.close

.open "ftc/overlay9_86", @Overlay86Start ; Free space overlay

.org @FreeSpace

; Continuation of bug 2 (asynchronous tileset loading) fix.
@SwapLeftAndRightSectorAreaIndexes:
  ; Swap sector indexes.
  ldr r1, [r13, 10h]
  ldr r0, [r13, 0Ch]
  str r0, [r13, 10h]
  str r1, [r13, 0Ch]
  ; Swap area indexes.
  ldr r1, [r13]
  ldr r0, [r13, 4h]
  str r0, [r13]
  str r1, [r13, 4h]
  b 020393ECh

; If the sector indexes of the source and destination are the same, we need to also check the area indexes.
@CheckAreaIndexIsDifferent:
  ldrsh r0, [r4, 0Ah] ; Load the area index of the currently loaded tileset.
  ldr r1, [r13, r5, lsl 2h] ; Load the destination area index.
  cmp r0, r1
  addeq r13, r13, 14h ; If the area indexes are the same, return from the function without loading the tileset.
  popeq r3-r9, r15
  b 0203940Ch ; Otherwise, continue on with loading the tileset.
@StoreLoadedSectorAreaIndexes:
  strh r0, [r1, 8h]
  strh r5, [r1, 0Ah]
  b 02039A88h



; Continuation of bug 3 (synchronous tileset loading) fix.
@LoadTilesetCheckUsePreviousAreaIndex:
  ; Check if r5 is -1, which indicates we are synchronously loading.
  mvn r1, 0h
  cmp r5, r1
  bne @ReturnToOriginalCode ; If it's not -1, we're async loading, so just go back to the original code without doing anything.
  b @LoadTilesetUsePreviousAreaIndex ; Otherwise, load the previous area index.

@ReturnToOriginalCode:
  ldr r1, =020ECA98h ; This is the one line of code we replaced in order to jump to free space.
  b 02039998h

@LoadTilesetUsePreviousAreaIndex:
  ldr r1, =020ECAA8h
  ldr r1, [r1] ; Load the previous area index value from 020ECAA8.
  cmp r1, r0 ; If the previous area index is also -1, that we're not in a transition room.
  ldreq r1, =020FFCB9h ; If not in a transition room, load the current area index the player is in from 020FFCB9 and use that, like what the vanilla code at 02038D1C was doing originally before we replaced it.
  ldreqb r5, [r1]
  beq @ReturnToOriginalCode
  ; Otherwise, we actually use the previous area index if it's not -1.
  mov r5, r1
  b @ReturnToOriginalCode



; Continuation of bug 4 (top screen map doesn't reload) fix.
@CheckReloadTopScreenMap:
  ldr r2, =020FFCB9h
  ldrb r2, [r2] ; Get current area index
  ; Note: r0 has the destination area index.
  cmp r2, r0 ; Check if the current and destination area are the same.
  beq @ReturnWithoutReloading ; If they are, don't reload the top screen since there would be no point.
  b @ReloadTopScreenMap
  
@ReturnWithoutReloading:
  bl 020395FCh ; LoadOverlayForSector. This is the one line of code we replaced in order to jump to free space. This must be called AFTER checking the current area index, since it will update the current area index to the new value.
  b 02038E18h
  
@ReloadTopScreenMap:
  bl 020395FCh ; LoadOverlayForSector.
  
  ldr r1, =0210078Dh
  ldrb r0, [r1] ; Check the current top screen.
  cmp r0, 5h
  bne 02038E18h ; Return to the original code if the current top screen is not the map screen. No need to change it then.
  
  ; Store 3 to 020F3678. 020F3678 is the current loading state of the top screen, with 3 meaning it should start to be loaded. So simply storing 3 here is enough to get the top screen to reload itself automatically.
  ldr r1, =020F3678h
  mov r0, 3h
  str r0, [r1]
  
  b 02038E18h ; Return to the original code.
  
  .pool

.close
