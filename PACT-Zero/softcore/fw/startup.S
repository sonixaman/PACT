.section .text.start
.global _start

_start:
	li 	sp, 0x00004000
	call	main
loop:
	j	loop
