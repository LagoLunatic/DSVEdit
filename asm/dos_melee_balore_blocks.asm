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

.close

.open "ftc/arm9.bin", 02000000h

.org 0x020C0290 ; Free space
@CheckDestroyBaloreBlocks:
  mov r5, r14
  mov r0, 0h
  bl 0220F81Ch
  cmp r0, 1h ; Check if Balore soul is active.
  beq @DestroyBaloreBlocks ; Destroy blocks if it is.
  ldr r0,=020F740Eh
  ldrb r0, [r0]
  cmp r0, 1h ; Otherwise check the current player character.
  bge @DestroyBaloreBlocks ; Destroy blocks if it's Julius/Alucard.
  b 02212E98h ; Didn't meet either condition, so return without destroying them.
@DestroyBaloreBlocks:
  mov r0, r5
  mov r1, r12
  mov r2, r4
  bl 021D5210h ; Call function to destroy blocks.
  b 02212E98h ; Return
  .pool

.close
