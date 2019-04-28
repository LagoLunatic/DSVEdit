.nds
.relativeinclude on
.erroronwarning on

; This patch allows the front and back entrances of Kalidus to be unlocked separately from one another.
; Normally you'd need to unlock the front entrance first, then the back entrance.
; Trying to unlock the back entrance first would crash the game.
; With this patch you can make the separate unlocks as follows:
; * Unlock the front entrance with Var A = 6 and Var B = 3
; * Unlock the back entrance with Var A = 6 and Var B = 1 (same as vanilla)

@Overlay86Start equ 0x022EB1A0
@FreeSpace equ @Overlay86Start + 0xB0

.open "ftc/arm9.bin", 02000000h

; Don't try to add the hand pointing to the new entrance in Kalidus, since that causes a crash when the back entrance is unlocked before the normal entrance.
.org 0x02045A10
  pop r3-r9, r15

.close

.open "ftc/overlay9_19", 021FFFC0h

; After checking if Var B is 1 or 2, also check if it's 3.
.org 0x0221D800
  b @CheckIsKalidusFrontEntranceUnlock

.close

.open "ftc/overlay9_86", @Overlay86Start

.org @FreeSpace
@CheckIsKalidusFrontEntranceUnlock:
  cmp r0, 3h ; Check if Var A is 3
  bne 0x0221D844 ; It's not, so return
  
  ; If it is, unlock the front entrance by setting room 06-00-00 as explored.
  mov r0, 6h
  mov r1, 0h
  mov r2, 0h
  bl 02046144h ; MapSetRoomExplored
  
  b 0x0221D844 ; Return

.close
