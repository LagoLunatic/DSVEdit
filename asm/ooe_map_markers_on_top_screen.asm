.nds
.relativeinclude on
.erroronwarning on

; This patch renders the map markers that the player can position to the top screen map.

@Overlay86Start equ 0x022EB1A0
@FreeSpace equ @Overlay86Start + 0x420

.open "ftc/arm9.bin", 02000000h

; In the function for rendering OAM objects to the top screen for the map, specifically right before creating the blinking player position indicator.
.org 0x020418EC
  b @DrawMarkersOnTopScreen

.org 0x02042894 ; Code that deletes the normal 2 OAM sprites on the top map screen
  b @DeleteMapMarkerOAMSpriteSlots

.close


.open "ftc/overlay9_86", @Overlay86Start

.org @FreeSpace
; reference: 02041C50 is where vanilla starts drawing the map markers
@DrawMarkersOnTopScreen:
  push r4, r5, r8, r9
  
  ldr r4, =020C553Ch ; Map sprite pointer (includes the marker)
  ldr r5, =@TopScreenMapMarkerOAMSpriteSlots
  
  ldr r8, =020FFCB9h
  ldrb r8, [r8] ; Read the current area index
  cmp r8, 12h
  bgt @DrawMarkersOnTopScreenReturn ; Only areas 00-12 have map markers
  mov r0, 0Ah ; Each area's markers take up 0xA bytes (5 markers times 2 bytes per marker)
  mul r8, r8, r0 ; Get the offset into the marker positions list for the current area
  ldr r0, =021006CFh ; List of map marker positions
  add r8, r0, r8
  
  mov r9, 0h ; Loop counter for number of markers we've drawn so far
  
@DrawMarkerOnTopScreenLoopStart:
  ; Create the marker
  mov r0, 1h ; Top screen
  bl 0203561Ch ; GetNextFreeOAMSpriteSlot
  str r0, [r5] ; Preserve a reference to this OAM sprite so we know to delete it later
  cmp r0, 0h ; No slots available
  beq @DrawMarkersOnTopScreenReturn
  
  str r4, [r0, 34h] ; Set sprite pointer
  mov r1, 2h
  strh r1, [r0, 3Ah] ; Set sprite frame index
  ldrb r1, [r8, 0h] ; Read Y pos of current marker
  mov r1, r1, lsl 0Ch ; Convert pixels to subpixels
  str r1, [r0, 24h] ; Set X pos
  ldrb r1, [r8, 1h] ; Read Y pos of current marker
  mov r1, r1, lsl 0Ch ; Convert pixels to subpixels
  str r1, [r0, 28h] ; Set Y pos
  mov r1, 1h
  str r1, [r0, 2Ch] ; Set Z pos
  
  add r5, r5, 4h
  add r8, r8, 2h
  add r9, r9, 1h
  cmp r9, 5h ; Draw 5 map markers in total
  blt @DrawMarkerOnTopScreenLoopStart
  
@DrawMarkersOnTopScreenReturn:
  pop r4, r5, r8, r9
  mov r0, r8 ; Replace the line we overwrote to jump here
  b 0x020418F0

@TopScreenMapMarkerOAMSpriteSlots:
  .word 0
  .word 0
  .word 0
  .word 0
  .word 0

@DeleteMapMarkerOAMSpriteSlots:
  ldr r4, =@TopScreenMapMarkerOAMSpriteSlots
  mov r6, 0h
@DeleteMapMarkerOAMSpriteSlotLoopStart:
  ; Delete the marker
  ldr r0, [r4]
  bl 0203571Ch ; MarkOAMSpriteFrameSlotAsFree
  add r4, 4h
  add r6, r6, 1h
  cmp r6, 5h ; Delete 5 map markers total
  blt @DeleteMapMarkerOAMSpriteSlotLoopStart
  b 0x020428F4

.pool ; Single pool for all the new code we added

.close
