.nds
.relativeinclude on
.erroronwarning on

; This patch renders the map markers that the player can position to the top screen map.

; Note that because the top and bottom screen have separate map graphics and palettes, in order for this patch to actually show anything you must also copy the map marker from the bottom screen UI's graphics and palettes the top screen's map graphics and palettes.
; Specifically you must:
; * Copy palette 04 in palette list 022C1554 to palette 05 in palette list 022C1490
; * Copy the 16x16 icon at position (32,0) in GFX page 022CDA9C (two dimensional) to position (112,0) in GFX page 022CBA90 (one dimensional)

@Overlay119Start equ 0x02308EC0
@FreeSpace equ @Overlay119Start + 0x400

.open "ftc/arm9.bin", 02000000h

; In the function for rendering OAM objects to the top screen for the map, specifically right after creating the blinking player position indicator.
.org 0x0202E3B0
  b @DrawMarkersOnTopScreen

.close


.open "ftc/overlay9_119", @Overlay119Start

.org @FreeSpace
@DrawMarkersOnTopScreen:
  push r0, r4, r5, r6, r7, r8, r9
  ldr r4, =020FC064h ; Top screen OAM sprites list
  ldr r5, =500Eh ; OAM attribute 2 (GFX tile index E, palette index 5)
  
  ldr r8, =02111785h
  ldrb r8, [r8] ; Read the current area index
  cmp r8, 9h
  bgt @DrawMarkersOnTopScreenReturn ; Only areas 0-9 have map markers
  mov r0, 6h ; Each area's markers take up 6 bytes (3 markers times 2 bytes per marker)
  mul r8, r8, r0 ; Get the offset into the marker positions list for the current area
  ldr r0, =0211196Eh ; List of map marker positions
  add r8, r0, r8
  
  mov r6, 20h ; Default marker X position
  mov r7, 10h ; Default marker Y position
  
  mov r9, 0h ; Loop counter for number of markers we've drawn so far
  
@DrawMarkerOnTopScreenLoopStart:
  ldrb r1, [r8, 0h] ; Read X pos of current marker
  cmp r1, r6 ; Check if the X pos is different from its default position
  bne @DrawMarkerOnTopScreenLoopCreateMarker
  ldrb r1, [r8, 1h] ; Read Y pos of current marker
  cmp r1, r7 ; Check if the Y pos is different from its default position
  ; If both X and Y are at the default position, we assume this marker has not been moved, so we don't draw this marker.
  beq @DrawMarkerOnTopScreenLoopContinue
  
@DrawMarkerOnTopScreenLoopCreateMarker:
  mov r0, 1h ; Top screen
  bl 020158FCh ; GetNextFreeOAMSlotIndex
  cmp r0, -1h ; No slots available
  beq @DrawMarkersOnTopScreenReturn
  
  add r0, r4, r0, lsl 3h ; Get pointer to the free OAM slot
  ldrb r1, [r8, 1h] ; Read Y pos of current marker
  strh r1, [r0] ; OAM attribute 0 (Y pos, OBJ shape square)
  ldrb r1, [r8, 0h] ; Read X pos of current marker
  orr r1, r1, 4000h ; Insert OBJ size 16x16 into OAM attribute
  strh r1, [r0, 2h] ; OAM attribute 1 (X pos, OBJ size 16x16)
  strh r5, [r0, 4h] ; OAM attribute 2
  
@DrawMarkerOnTopScreenLoopContinue:
  add r6, r6, 10h ; The default X pos of every marker is 0x10 pixels to the right of the last one
  add r8, r8, 2h
  add r9, r9, 1h
  cmp r9, 3h ; Draw 3 map markers in total
  blt @DrawMarkerOnTopScreenLoopStart
  
@DrawMarkersOnTopScreenReturn:
  pop r0, r4, r5, r6, r7, r8, r9
  and r7, r7, 0FFh ; Replace the line we overwrote to jump here
  b 0x0202E3B4 ; Return


.pool ; Single pool for all the new code we added

.close
