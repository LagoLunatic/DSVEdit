.nds
.relativeinclude on
.erroronwarning on

; This patch allows for warp points in PoR to take you between different areas.
; To do this, simply press L or R on the warp select screen and it will cycle through the different area maps (only ones that you've unlocked at least one warp point for).
; This patch also adds a left and right arrow button to the warp select screen, and touching them with the touch screen cycles through maps the same way the L and R buttons do.

@Overlay119Start equ 0x02308EC0
@FreeSpace equ @Overlay119Start + 0x19C

.open "ftc/arm9.bin", 02000000h

.org 0x02082364 ; Update code for the warp select screen
  beq @CheckShouldSwitchAreaOnWarpScreen

.org 0x0202E038 ; In the function for rendering OAM objects to the bottom screen on the warp screen
  b @DrawArrowsOnBottomScreen

.org 0x02082C7C ; Warp point update code, specifically the part where it's just about to open the warp select screen
  b @SetAreaIndexAndRedrawMapOnWarpScreenOpen

; Make the code that detects what warp point you touched on the touch screen use the correct map draw offsets.
; Read the area index from 0211AA71 instead of 02111785.
.org 0x0208259C
  add r0, r0, 24000h
  ldrb r0, [r0, 801h]
.org 0x020825B8
  add r0, r1, 24000h
.org 0x020825C0
  ldrb r0, [r0, 801h]

; Fix the code that runs right before deciding to warp that determines if the warp you selected it he one you're already at or not.
; Normally it only checks the warp index, but we need to also check the area index now.
.org 0x0208231C
  b @CheckSelectedWarpInCurrentAreaForButtons
.org 0x02082618
  b @CheckSelectedWarpInCurrentAreaForTouchScreen

; Code run when warping, to determine what area, sector, and room indexes you should be warping to.
.org 0x020832C0
  ; Fix sector index
  bl @GetSectorIndexByRoomPosOnSelectedAreaMap
.org 0x020832D0
  ; Fix room index
  bl @GetRoomIndexByRoomPosOnSelectedAreaMap
.org 0x020832F4
  ; Fix area index
  ldr r0, =021368AFh
  ldrb r0, [r0]
  mov r1, r8
  mov r2, r7
  b 0x0208330C
  .pool

.close


.open "ftc/overlay9_119", @Overlay119Start

.org @FreeSpace
@CheckShouldSwitchAreaOnWarpScreen:
  ands r0, r1, 0100h ; R button
  bne @IncreaseAreaIndexOnWarpScreen
  ands r0, r1, 0200h ; L button
  bne @DecreaseAreaIndexOnWarpScreen
  
  ldr r0, =020FC4B4h
  ldrb r1, [r0, 1h] ; Check if touch screen just touched
  cmp r1, 0h
  beq 0x02082398 ; Return
  
  ldrsh r1, [r0, 6h] ; Y pos touched
  cmp r1, 58h
  ble 0x02082398 ; Return
  cmp r1, 68h
  bge 0x02082398 ; Return
  
  ldrsh r1, [r0, 4h] ; X pos touched
  cmp r1, 10h
  blt @DecreaseAreaIndexOnWarpScreen
  cmp r1, 0F0h
  bgt @IncreaseAreaIndexOnWarpScreen
  
  b 0x02082398 ; Return to normal code

@IncreaseAreaIndexOnWarpScreen:
  ldr r1, =021368AFh
  ldrb r0, [r1]
  add r0, r0, 1h
  cmp r0, 9h
  movgt r0, 0h
  strb r0, [r1]
  
  bl @CheckSelectedAreaHasAnyExploredWarpPoints
  ; If the next area's map doesn't have any warp points explored yet, increase the area index to try again.
  cmp r0, 0h
  beq @IncreaseAreaIndexOnWarpScreen
  
  b @UpdateAreaOnWarpScreen

@DecreaseAreaIndexOnWarpScreen:
  ldr r1, =021368AFh
  ldrb r0, [r1]
  sub r0, r0, 1h
  cmp r0, 0h
  movlt r0, 9h
  strb r0, [r1]
  
  bl @CheckSelectedAreaHasAnyExploredWarpPoints
  ; If the previous area's map doesn't have any warp points explored yet, decrease the area index to try again.
  cmp r0, 0h
  beq @DecreaseAreaIndexOnWarpScreen
  
  b @UpdateAreaOnWarpScreen

@UpdateAreaOnWarpScreen:
  push r4
  ldr r4, =021368AFh
  
  ; Update the area index for the warp selection screen to use (mostly seems to affect the map draw offset)
  ldrb r0, [r4] ; Read the area index the player has selected
  ldr r1, =0211AA71h
  strb r0, [r1]
  
  ; Draw the map for the new area.
  ldrb r0, [r4] ; Read the area index the player has selected
  bl 0202F138h ; MapDraw???ForArea
  
  ; Call various functions necessary to refresh the map.
  bl 02004000h ; MapShowChanges1??
  bl 0202E854h ; MapShowChanges2??
  bl 0203072Ch ; WarpScreenSetWarpCycleOrder
  
  ; Set the selected warp point index to 0 (at 021368F5). This is to avoid an out-of-range warp being selected.
  mov r0, 0h
  strb r0, [r4, 46h]
  
  ; Update the area name on the top screen.
  ldrb r0, [r4, 0Dh] ; Read the area name index for warp 0 (at 021368BC)
  bl 02055CF4h ; SetTopScreenAreaName
  
  pop r4
  b 0x02082398 ; Return to normal code


@GetRoomIndexByRoomPosOnSelectedAreaMap:
  push r14
  ldr r2, =021368AFh
  ldrb r2, [r2] ; Area index of the selected map
  bl 0202DBF4h ; GetMapTileMetadata
  and r0, r0, 3Fh
  pop r15
@GetSectorIndexByRoomPosOnSelectedAreaMap:
  push r14
  ldr r2, =021368AFh
  ldrb r2, [r2] ; Area index of the selected map
  bl 0202DBF4h ; GetMapTileMetadata
  mov r0, r0, asr 6h
  and r0, r0, 0Fh
  pop r15


@CheckSelectedAreaHasAnyExploredWarpPoints:
  push r3-r7,r14
  
  ldr r4, =021368AFh
  ldrb r4, [r4] ; Area index of the selected map
  
  mov r0, r4
  bl 02030570h ; MapGetExploredTileListForArea
  mov r5, r0
  
  mov r0, r4
  bl 02030214h ; MapGetMetadataListPointer
  mov r6, r0
  
  mov r0, r4
  bl 02030710h ; MapGetTotalNumTiles
  mov r7, r0 ; Total number of tiles
  
  mov r3, 0h ; Current tile index
  
@CheckTileIsExploredWarpPointLoopStart:
  ldr r1, [r6, r3, lsl 2h] ; Read the metadata for this tile
  ands r1, r1, 4000h ; Check if it's a warp point
  beq @CheckTileIsExploredWarpPointLoopContinue
  
  mov r0, r3, asr 3h ; Get the index of the halfword in the explored tiles list by dividing by 8 (8 tiles per halfword)
  mov r0, r0, lsl 1h ; Get the offset of the halfword in the explored tiles list
  ldrh r1, [r5, r0]
  and r0, r3, 7h ; Get the index of the tile within the halfword
  mov r0, r0, lsl 1h ; Get the index of the bit within the halfword
  mov r1, r1, asr r0
  and r1, r1, 3h ; Get the bits for this tile
  cmp r1, 3h
  beq @CheckSelectedAreaHasAnyExploredWarpPointsFoundOne
  
@CheckTileIsExploredWarpPointLoopContinue:
  add r3, r3, 1h
  cmp r3, r7
  blt @CheckTileIsExploredWarpPointLoopStart
  
@CheckSelectedAreaHasAnyExploredWarpPointsNoneFound:
  mov r0, 0h
  b @CheckSelectedAreaHasAnyExploredWarpPointsReturn
@CheckSelectedAreaHasAnyExploredWarpPointsFoundOne:
  mov r0, 1h
@CheckSelectedAreaHasAnyExploredWarpPointsReturn:
  pop r3-r7,r15


; Need to initialize the area index when the player opens the warp screen.
; This is so pressing L or R takes you to the previous or next area from the area you're actually in, as opposed to the area index last placed in 021368AF (e.g. the last area you viewed in the map menu).
@SetAreaIndexAndRedrawMapOnWarpScreenOpen:
  ldrb r0, [r0, 515h] ; Read the current area index from 02111785
  ldr r1, =021368AFh
  strb r0, [r1]
  
  ; Also redraw the map for the current area.
  ; This is to fix a bug in the case where the player has the info screen on the top screen and backs out of the warp menu when an area that isn't the current area is selected, and then re-opened the warp select menu.
  ; In that situation, the most recently drawn map would be an area that isn't the current area, which could cause the warp points shown on screen to not be properly offset.
  bl 0202F138h ; MapDraw???ForArea
  
  bl 02004000h ; MapShowChanges1?? ; Replace the line we overwrote to jump here
  b 0x02082C80 ; Return to normal code

@CheckSelectedWarpInCurrentAreaForButtons:
  cmp r1, r0 ; Replace the line we overwrote to jump here which checks if the warp index selected is the warp index the player is physically at already
  bne 0x02082334
  
  ldr r0, =02111785h ; Area index the player is actually in
  ldrb r0, [r0]
  ldr r1, =021368AFh ; Area index of the map currently displayed
  ldrb r1, [r1]
  cmp r0, r1
  beq 0x02082320 ; If the warp the player selected is in the area they're physically located in, just close the warp screen as normal.
  b 0x02082334 ; Otherwise, take the warp. Even though the warp index is the same, the area index being different means it's a different warp point.

@CheckSelectedWarpInCurrentAreaForTouchScreen:
  bne 0x02082644 ; Replace the line we overwrote to jump here which checks if the warp index selected is the warp index the player is physically at already
  
  ldr r1, =02111785h ; Area index the player is actually in
  ldrb r1, [r1]
  ldr r2, =021368AFh ; Area index of the map currently displayed
  ldrb r2, [r2]
  cmp r1, r2
  beq 0x0208261C ; If the warp the player selected is in the area they're physically located in, just close the warp screen as normal.
  b 0x02082644 ; Otherwise, take the warp. Even though the warp index is the same, the area index being different means it's a different warp point.


@DrawArrowsOnBottomScreen:
  ; Draws arrow icons on the right and left of the screen to visually indicate that the area can be switched by touching the screen.
  push r4, r5, r6
  ldr r4, =020FBC64h ; Bottom screen OAM sprites list
  mov r5, 0058h ; OAM attribute 0 (Y pos 58, OBJ shape square)
  ldr r6, =4002h ; OAM attribute 2 (GFX tile index 2)
  
  ; Create the right arrow
  mov r0, 0h ; Bottom screen
  bl 020158FCh ; GetNextFreeOAMSlotIndex
  cmp r0, -1h ; No slots available
  beq @DrawArrowsOnBottomScreenReturn
  
  add r1, r4, r0, lsl 3h
  strh r5, [r1]
  ldr r0, =40F0h ; OAM attribute 1 (X pos F0, OBJ size 16x16)
  strh r0, [r1, 2h]
  strh r6, [r1, 4h]
  
  ; Create the left arrow
  mov r0, 0h ; Bottom screen
  bl 020158FCh ; GetNextFreeOAMSlotIndex
  cmp r0, -1h ; No slots available
  beq @DrawArrowsOnBottomScreenReturn
  
  add r1, r4, r0, lsl 3h
  strh r5, [r1]
  ldr r0, =5000h ; OAM attribute 1 (X pos 0, horizontal flip, OBJ size 16x16)
  strh r0, [r1, 2h]
  strh r6, [r1, 4h]
  
@DrawArrowsOnBottomScreenReturn:
  pop r4, r5, r6
  mov r0, 0h ; Replace the line we overwrote to jump here
  b 0x0202E03C ; Return


.pool ; Single pool for all the new code we added

.close
