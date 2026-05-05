MEMORY {
	RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 16K
}

SECTIONS {
	.text : {
		*(.text.start)
		*(.text*)
	} > RAM

	.data : {
		*(.data*)
	} > RAM
	
	.bss : {
		*(.bss*)
	} > RAM
}
