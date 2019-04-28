.nds
.relativeinclude on
.erroronwarning on

; This patch allows for warp points in OoE to take you between different areas.
; To do this, simply press L or R on the warp select screen and it will cycle through the different area maps (only ones that you've unlocked at least one warp point for).
; This patch also adds a left and right arrow button to the warp select screen, and touching them with the touch screen cycles through maps the same way the L and R buttons do.

@Overlay86Start equ 0x022EB1A0
@FreeSpace equ @Overlay86Start + 0xCC

.open "ftc/arm9.bin", 02000000h

.org 0x020454F8 ; Update code for the warp select screen
  beq @CheckShouldSwitchAreaOnWarpScreen

.org 0x02041AC4 ; In the function for initializing OAM sprite objects on the bottom screen when opening the warp screen
  b @DrawArrowsOnBottomScreen

.org 0x020428B4 ; Code that deletes the normal 0xA OAM sprites on the warp screen
  b @DeleteArrowOAMSpriteSlots

; Make the code that offsets the blinking position indicator use the correct map draw offsets.
.org 0x020425E0
  bl @GetSelectedMapAreaIndex
.org 0x02042614
  bl @GetSelectedMapAreaIndex

; Make the code that detects what warp point you touched on the touch screen use the correct map draw offsets.
.org 0x02045764
  bl @GetSelectedMapAreaIndex
.org 0x02045774
  bl @GetSelectedMapAreaIndex

; Fix the code that runs right before deciding to warp that determines if the warp you selected it he one you're already at or not.
; Normally it only checks the warp index, but we need to also check the area index now.
.org 0x02045494
  b @CheckSelectedWarpInCurrentAreaForButtons
.org 0x020457D8
  b @CheckSelectedWarpInCurrentAreaForTouchScreen

.close

.open "ftc/overlay9_22", 02223E00h

.org 0x022A5134 ; Warp point update code, specifically the part where it's just about to open the warp select screen
  b @SetAreaIndexOnWarpScreenOpen

; Code run when warping, to determine what area, sector, and room indexes you should be warping to.
.org 0x022A521C
  ; Fix sector index
  bl @GetSectorIndexByRoomPosOnSelectedAreaMap
.org 0x022A522C
  ; Fix room index
  bl @GetRoomIndexByRoomPosOnSelectedAreaMap
.org 0x022A5260
  ; Fix area index
  bl @GetSelectedMapAreaIndex

.close


.open "ftc/overlay9_86", @Overlay86Start

.org @FreeSpace
@CheckShouldSwitchAreaOnWarpScreen:
  ands r0, r1, 0100h ; R button
  bne @IncreaseAreaIndexOnWarpScreen
  ands r0, r1, 0200h ; L button
  bne @DecreaseAreaIndexOnWarpScreen
  
  ldr r0, =02101124h
  ldrb r1, [r0, 1h] ; Check if touch screen just touched
  cmp r1, 0h
  beq 0x02045548 ; Return
  
  ldrsh r1, [r0, 6h] ; Y pos touched
  cmp r1, 58h
  ble 0x02045548 ; Return
  cmp r1, 68h
  bge 0x02045548 ; Return
  
  ldrsh r1, [r0, 4h] ; X pos touched
  cmp r1, 1Ch
  blt @DecreaseAreaIndexOnWarpScreen
  cmp r1, 0E4h
  bgt @IncreaseAreaIndexOnWarpScreen
  
  b 0x02045548 ; Return to normal code

@IncreaseAreaIndexOnWarpScreen:
  ldr r1, =0214B08Ch
  ldrb r0, [r1]
  add r0, r0, 1h
  cmp r0, 12h
  movgt r0, 0h
  strb r0, [r1]
  
  bl @CheckSelectedAreaHasAnyExploredWarpPoints
  ; If the next area's map doesn't have any warp points explored yet, increase the area index to try again.
  cmp r0, 0h
  beq @IncreaseAreaIndexOnWarpScreen
  
  b @UpdateAreaOnWarpScreen

@DecreaseAreaIndexOnWarpScreen:
  ldr r1, =0214B08Ch
  ldrb r0, [r1]
  sub r0, r0, 1h
  cmp r0, 0h
  movlt r0, 12h
  strb r0, [r1]
  
  bl @CheckSelectedAreaHasAnyExploredWarpPoints
  ; If the previous area's map doesn't have any warp points explored yet, decrease the area index to try again.
  cmp r0, 0h
  beq @DecreaseAreaIndexOnWarpScreen
  
  b @UpdateAreaOnWarpScreen

@UpdateAreaOnWarpScreen:
  push r4
  ldr r4, =0214B08Ch
  
  ; Draw the map for the new area.
  ldrb r0, [r4] ; Read the area index the player has selected
  bl 02043480h ; MapDraw???ForArea
  
  ; Call various functions necessary to refresh the map.
  bl 02042E74h ; MapShowChanges1??
  bl 02042CE4h ; MapShowChanges2??
  bl 02042FF4h ; WarpScreenSetWarpCycleOrder
  
  ; Set the selected warp point index to 0 (at 0214B0F0). This is to avoid an out-of-range warp being selected.
  mov r0, 0h
  strb r0, [r4, 64h]
  
  ; Update the area name on the top screen.
  mov r0, 4h
  mov r1, 1h
  ldrb r2, [r4, 3Fh] ; Read the area name index for warp 0 (at 0214B0CB)
  bl 020AEDB4h ; SetTopScreenAreaName
  
  
  ; Update the OAM warp sprite icons to match the newly selected area's warp points.
  ; Also hide/show sprites as necessary if the number of warps differs.
  push r5-r9
  ldr r4, [r4] ; Selected area index
  ldr r8, =0214B0C7h ; List of active warp points on the currently selected map
  ldr r5, =0214B188h ; List of warp point OAM sprites used by the warp select screen
  ldr r9, =0214B0F1h
  ldrb r9, [r9] ; Read the total number of warp points active on the selected map
  mov r7, 0h
  @CreateWarpPointOAMSpritesLoopStart:
  ldr r6, [r5]
  
  cmp r7, r9 ; Check if the warp we're on is past the end of the active warps list for this area
  bge @CreateWarpPointOAMSpritesLoopSetWarpInvisible ; If so, simply deactivate it
  
@CreateWarpPointOAMSpritesLoopSetWarpVisible:
  mov r0, r4
  bl 02042F7Ch ; MapGetDrawXOffset
  ldrb r1, [r8] ; Warp X pos in tiles
  mov r0, r0, lsl 3h
  add r0, r0, r1, lsl 2h
  add r0, r0, 2h
  mov r0, r0, lsl 0Ch
  str r0, [r6, 24h] ; Store X pos to warp point OAM sprite
  
  mov r0, r4
  bl 02042F94h ; MapGetDrawYOffset
  ldrb r1, [r8, 1h] ; Warp Y pos in tiles
  mov r0, r0, lsl 3h
  add r0, r0, r1, lsl 2h
  add r0, r0, 2h
  mov r0, r0, lsl 0Ch
  str r0, [r6, 28h] ; Store Y pos to warp point OAM sprite
  
  ; Set the visible bit.
  ldrh r0, [r6, 2h]
  orr r0, r0, 20h
  strh r0, [r6, 2h]
  b @CreateWarpPointOAMSpritesLoopContinue
  
@CreateWarpPointOAMSpritesLoopSetWarpInvisible:
  ; Unset the visible bit
  ldrh r0, [r6, 2h]
  bic r0, r0, 20h
  strh r0, [r6, 2h]
  
@CreateWarpPointOAMSpritesLoopContinue:
  add r8, r8, 5h
  add r5, r5, 4h
  add r7, r7, 1h
  cmp r7, 8h
  blt @CreateWarpPointOAMSpritesLoopStart
  pop r5-r9
  
  
  pop r4
  b 0x02045548 ; Return to normal code


@GetRoomIndexByRoomPosOnSelectedAreaMap:
  push r14
  ldr r2, =0214B08Ch
  ldrb r2, [r2] ; Area index of the selected map
  bl 02044710h ; GetMapTileMetadata
  and r0, r0, 3Fh
  pop r15
@GetSectorIndexByRoomPosOnSelectedAreaMap:
  push r14
  ldr r2, =0214B08Ch
  ldrb r2, [r2] ; Area index of the selected map
  bl 02044710h ; GetMapTileMetadata
  mov r0, r0, asr 6h
  and r0, r0, 0Fh
  pop r15

@GetSelectedMapAreaIndex:
  push r14
  ldr r0, =0214B08Ch
  ldrb r0, [r0] ; Area index of the selected map
  pop r15


@CheckSelectedAreaHasAnyExploredWarpPoints:
  push r3-r7,r14
  
  ldr r4, =0214B08Ch
  ldrb r4, [r4] ; Area index of the selected map
  
  mov r0, r4
  bl 0204319Ch ; MapGetExploredTileListForArea
  mov r5, r0
  
  mov r0, r4
  bl 02043238h ; MapGetMetadataListPointer
  mov r6, r0
  
  mov r0, r4
  bl 02043180h ; MapGetTotalNumTiles
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
; This is so pressing L or R takes you to the previous or next area from the area you're actually in, as opposed to the area index last placed in 0214B08C (e.g. the last area you viewed in the map menu).
@SetAreaIndexOnWarpScreenOpen:
  ldr r1, =020FFCB9h
  ldrb r0, [r1] ; Read the current area index
  ldr r1, =0214B08Ch
  strb r0, [r1]
  b 0x022A526C ; Return to normal code


@CheckSelectedWarpInCurrentAreaForButtons:
  cmp r1, r0 ; Replace the line we overwrote to jump here which checks if the warp index selected is the warp index the player is physically at already
  bne 0x020454C4
  
  ldr r0, =020FFCB9h ; Area index the player is actually in
  ldrb r0, [r0]
  ldr r1, =0214B08Ch ; Area index of the map currently displayed
  ldrb r1, [r1]
  cmp r0, r1
  beq 0x0204549C ; If the warp the player selected is in the area they're physically located in, just close the warp screen as normal.
  b 0x020454C4 ; Otherwise, take the warp. Even though the warp index is the same, the area index being different means it's a different warp point.

@CheckSelectedWarpInCurrentAreaForTouchScreen:
  bne 0x0204581C ; Replace the line we overwrote to jump here which checks if the warp index selected is the warp index the player is physically at already
  
  ldr r1, =020FFCB9h ; Area index the player is actually in
  ldrb r1, [r1]
  ldr r2, =0214B08Ch ; Area index of the map currently displayed
  ldrb r2, [r2]
  cmp r1, r2
  beq 0x020457DC ; If the warp the player selected is in the area they're physically located in, just close the warp screen as normal.
  b 0x0204581C ; Otherwise, take the warp. Even though the warp index is the same, the area index being different means it's a different warp point.


@DrawArrowsOnBottomScreen:
  push r4, r5
  
  ldr r4, =020C553Ch ; Map sprite pointer (includes the pointing arrows)
  ldr r5, =@WarpScreenArrowsOAMSpriteSlots
  
  ; Create the left arrow
  mov r0, 0h ; Bottom screen
  bl 0203561Ch ; GetNextFreeOAMSpriteFramePointer
  str r0, [r5, 0h] ; Preserve a reference to this OAM sprite so we know to delete it later
  cmp r0, 0h ; No slots available
  beq @DrawArrowsOnBottomScreenReturn
  
  str r4, [r0, 34h] ; Set sprite pointer
  mov r1, 5h
  strh r1, [r0, 3Ah] ; Set sprite frame index
  mov r1, 0C000h
  str r1, [r0, 24h] ; Set X pos
  mov r1, 60000h
  str r1, [r0, 28h] ; Set Y pos
  mov r1, 2h
  str r1, [r0, 2Ch] ; Set Z pos
  
  ; Create the right arrow
  mov r0, 0h ; Bottom screen
  bl 0203561Ch ; GetNextFreeOAMSpriteFramePointer
  str r0, [r5, 4h] ; Preserve a reference to this OAM sprite so we know to delete it later
  cmp r0, 0h ; No slots available
  beq @DrawArrowsOnBottomScreenReturn
  
  str r4, [r0, 34h] ; Set sprite pointer
  mov r1, 6h
  strh r1, [r0, 3Ah] ; Set sprite frame index
  mov r1, 0F4000h
  str r1, [r0, 24h] ; Set X pos
  mov r1, 60000h
  str r1, [r0, 28h] ; Set Y pos
  mov r1, 2h
  str r1, [r0, 2Ch] ; Set Z pos
  
@DrawArrowsOnBottomScreenReturn:
  pop r4, r5
  b 0x02042420

@WarpScreenArrowsOAMSpriteSlots:
  .word 0
  .word 0

@DeleteArrowOAMSpriteSlots:
  ldr r4, =@WarpScreenArrowsOAMSpriteSlots
  ; Delete left arrow
  ldr r0, [r4, 0h]
  bl 0203571Ch ; MarkOAMSpriteFrameSlotAsFree
  ; Delete right arrow
  ldr r0, [r4, 4h]
  bl 0203571Ch ; MarkOAMSpriteFrameSlotAsFree
  b 0x020428F4

.pool ; Single pool for all the new code we added

.close
