.nds
.relativeinclude on
.erroronwarning on

; This allows Charlotte's spells to gain SP like subweapons do.
; Once a spell is mastered, it will act like it is fully-charged even if half-charged.
; If you fully charge a spell that is also mastered, it acts super-charged, doing 3x damage and possibly having more projectiles than normal.
; Note that unlike subweapons, spells do not gradually scale in damage as you gain SP. They only suddenly increase once mastered.

.open "ftc/overlay9_0", 021CDF60h

.org 0x021D9E10
  ; When the enemy is hit, it checks the type of the attack to see if it's a subweapon (damage type bit 02000000).
  ; If it is, the enemy is marked so that it should give SP whenever it dies.
  ; We change the damage type bit mask it checks to 06000000, so it gives SP if it's hit by either a subweapon or a spell.
  ands r0, r0, 06000000h

.org 0x021D9B10
  ; When SP is added to the player's current skill, it only checks Jonathan's equipped skill.
  ; So we need to change it to add to the controlled character's equipped skill's SP.
  ; We also change the Master Ring checks to check the controlled character instead of always Jonathan.
  ; Note: Because this adds SP to whatever player character is currently controlled, using your partner's skill with the skill cube does not give SP to your partner, but to you instead. Same with the Master Ring checks.
  
  ; r0 already has 020CA580 in it from the line before, so we add 47000 to it to get 02111580.
  add r1, r0, 47000h
  
  ; Checks if the game mode is Jonathan mode
  ldrb r0, [r1,09D1h] ; 02111F51, current game mode
  cmp r0, 0h
  bne 21D9C00h
  
  ; Checks if the enemy had ever been hit by a subweapon (or a spell now)
  ldr r0,[r8,120h] ; Enemy+120
  ands r0,r0,2000h
  beq 21D9C00h
  
  ldrb r0, [r1,09D7h] ; 02111F57, current player number
  mov r2,6Ch ; Size of each player's info is 0x6C
  mul r2,r0,r2
  add r1,r1,r2
  ldrb r0, [r1,0BFEh] ; Currently equipped skill (0211217E or 021121EA). (Note that this is technically a halfword, but we need to read it as a byte because the opcode to read halfwords has more limited immediate offsets.)
  ; Check that there is an equipped skill.
  cmp r0, 0h
  beq 21D9C00h
  
  ldrb r3,[r6,0Dh] ; Read SP given by this enemy
  ldrb r2, [r1,0C06h] ; Currently equipped accessory 1 (02112186 or 021121F2). (Note that this is technically a halfword, but we need to read it as a byte because the opcode to read halfwords has more limited immediate offsets.)
  cmp r2, 0Eh ; Check if Master Ring is equipped
  moveq r3,r3,lsl 1h ; Double given SP if so
  ldrb r2, [r1,0C08h] ; Currently equipped accessory 2 (02112188 or 021121F4). (Note that this is technically a halfword, but we need to read it as a byte because the opcode to read halfwords has more limited immediate offsets.)
  cmp r2, 0Eh ; Check if Master Ring is equipped
  moveq r3,r3,lsl 1h ; Double given SP if so

; Fixes the multiplier on spells not increasing by 1 when the spell is mastered.
.org 0x02214DC8
  ldrneb r2, [r0,11Eh] ; Where the spell's multiplier is stored
  addne r2, r2, r4 ; r4 has the bonus multiplier for fully charging the spell (0 or 1)
  strneb r2, [r0,11Eh]

; Fixes Charlotte not yelling out the name of the spell when it's charged to level 3.
.org 0x021F227C
  cmp r0, 1h
  beq 0x021F22AC

.close

.open "ftc/arm9.bin", 02000000h

.org 0x0203C894
  ; Fixes mastered spells not having yellow names in Charlotte's spell equip menu.
  ; Normally this line skipped making the name yellow if the skill index was >= 0x27 (the first spell index), so we change it to >= 0x51 (the first dual crush index).
  cmp r0, 51h

.close
