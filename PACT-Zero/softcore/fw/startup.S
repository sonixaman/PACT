.section .text.start
.global _start

_start:
	li sp, 0x00004000 
	jal main 
	
loop:
	j loop

