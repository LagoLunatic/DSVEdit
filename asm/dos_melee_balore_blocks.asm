.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_0", 0219E3E0h

; This makes it so that all melee weapons can break balore blocks, not just Julius's whip.

.org 0x02212AB0 ; Branch of a switch statement taken for all melee weapons except Julius's whip.
  b 02212D64h ; Instead take the branch for Julius's whip.

; Next we need to make sure the player has Balore's soul.

.org 0x02212E94 ; Line in the whip code that would normally call 021D5210 to break the blocks.
  b @CheckDestroyBaloreBlocks ; Instead jump to our own code to check if the player has Balore's soul.

; There's a bug where weapons with small hitboxes won't break all the blocks they touch.
.org 0x02212E34
  add r3, r3, 8h ; Add 8 pixels to the hitbox height so it will be rounded up to the nearest 16px instead of down.

; There's a bug where the whip code only checks the weapon's first hitbox, even though some weapons have two hitboxes at once.
; To do this we need a new variable, r6, to keep track of whether we're on the first hitbox or the second one.
; We also need to preserve the pointer to the weapon entity (argument r0 passed to this function).
; So change all the push/pop statements for this function to include r0 and r6 (instead of just r4,r5,r14).
.org 0x02212DB4
  push r0,r4-r6,r14
.org 0x02212DCC
  popne r0,r4-r6,r14
.org 0x02212DE8
  popeq r0,r4-r6,r14
.org 0x02212E04
  popeq r0,r4-r6,r14
.org 0x02212E9C
  pop r0,r4-r6,r14

.close

.open "ftc/arm9.bin", 02000000h

.org 0x020C0290 ; Free space
@CheckDestroyBaloreBlocks:
  push r14 ; Preserve r14 because it has an argument we'll need to call the function to break the blocks later.
  mov r0, 0h
  bl 0220F81Ch
  pop r14
  cmp r0, 1h ; Check if Balore soul is active.
  beq @DestroyBaloreBlocks ; Destroy blocks if it is.
  ldr r0,=020F740Eh
  ldrb r0, [r0]
  cmp r0, 1h ; Otherwise check the current player character.
  bge @DestroyBaloreBlocks ; Destroy blocks if it's Julius/Alucard.
  b 02212E98h ; Didn't meet either condition, so return without destroying them.
@DestroyBaloreBlocks:
  mov r0, r14
  mov r1, r12
  mov r2, r4
  bl 021D5210h ; Call function to destroy blocks.
  
; Now we need to check the second hitbox.
  cmp r6, 1h
  addeq r13,r13,1Ch ; If r6 is 1, we already checked both hitboxes, so return.
  popeq r0,r4-r6,r14
  bxeq r14
  mov r6, 1h ; Set r6 to 1 to indicate that we already checked both hitboxes.
  ldr r0, [r13,1Ch] ; We extract the pointer to the weapon entity from the stack (argument r0 to the whip function).
  bl 02012DB0h ; Get the weapon's hitbox pointer.
  add r0, r0, 0Ah ; Add 0x0A to get the second hitbox pointer.
  b 02212DF8h ; Jump back to inside the whip function so it checks the second hitbox.
  .pool

.close
