
; By DevAnj

.nds
.relativeinclude on
.erroronwarning on

.open "ftc/overlay9_0", 021CDF60h

;code to make shurikens throw only 2 shurikens instead of 4, regardless of mastery

.org 0x0220F31C
cmp r0,2h
b 220F34Ch ;skips the code that spawns 2 extra shurikens

;fix darts to require the same level of accuracy to score hits even when mastered

.org 0x022144C8
mov r1, 1h ;targeting system remains same regardless of mastery

.close
