//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.arch armv8-a
.equ LOAD_ADDRESS, 0x8000
.equ CODE_SIZE, END-START // everything beyond the HEADER is code

//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;HEADER;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ELF_HEADER:
	.byte 0x7F,'E','L','F' // magic number to indicate ELF file
	.byte 0x02 // 0x1 for 32-bit, 0x2 for 64-bit
	.byte 0x01 // 0x1 for little endian, 0x2 for big endian
	.byte 0x01 // 0x1 for current version of ELF
	.byte 0x00 // 0x9 for FreeBSD, 0x3 for Linux (doesn't seem to matter)
	.byte 0x00 // ABI version (ignored?)
	.fill 7, 1, 0x00 // 7 padding bytes
	.short 0x0002 // executable file
	.short 0x00B7 // ARMv8a
	.word 0x00000001 // version 1
	.quad LOAD_ADDRESS+0x78 // entry point for our program
	.quad 0x0000000000000040 // 0x40 offset from ELF_HEADER to PROGRAM_HEADER
	.quad 0x0000000000000000 // section header offset (we don't have this)
	.word 0x00000000 // unused flags
	.short 0x0040 // 64-byte size of ELF_HEADER
	.short 0x0038 // 56-byte size of each program header entry
	.short 0x0001 // number of program header entries (we have one)
	.short 0x0000 // size of each section header entry (none)
	.short 0x0000 // number of section header entries (none)
	.short 0x0000 // index in section header table for section names (waste)
PROGRAM_HEADER:
	.word 0x00000001 // 0x1 for loadable program segment
	.word 0x00000007 // read/write/execute flags
	.quad 0x0000000000000078 // offset of code start in file image (0x40+0x38)
	.quad LOAD_ADDRESS+0x78 // virtual address of segment in memory
	.quad 0x0000000000000000 // physical address of segment in memory (ignored?)
	.quad CODE_SIZE // size (bytes) of segment in file image
	.quad CODE_SIZE+gpiomem_length // size (bytes) of segment in memory
	.quad 0x0000000000000000 // alignment (doesn't matter, only 1 segment)

//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:	// address label representing the entry point of our program

.equ PIN, 19	// select LED GPIO pin here

// these memory offsets are calculated automatically
.equ GPFSEL_OFFSET, 0x4*(PIN/10)
.equ GPLEV_OFFSET, 0x34+0x4*(PIN/32)
.equ BIT_OFFSET, 3*(PIN%10)

// /dev/gpiomem size, really don't need all this
.equ gpiomem_length, 4096

	// Open /dev/gpiomem
	mov x0, -100    	// dirfd = AT_FDCWD (current directory)
	mov x1, LOAD_ADDRESS
	add x1, x1, gpiomem_path // position independent LDR basically
	mov w2, 2       	// flags = O_RDWR
	mov w3, 0            	// mode (not used)
	mov w8, 56   		// syscall number
	svc 0                	// Invoke syscall

	mov 	x5, 0
	mov 	w4, w0
	mov	w3, 1
	mov	w2, 3
	mov	x1, gpiomem_length // seems to work "the same" no matter what you put.
	mov 	x0, LOAD_ADDRESS // This line and below as well. Curious...
	add 	x0, x0, mapped_memory // (position independent LDR basically)
	mov 	x8, 222
	svc 	0
	// x0 points to mapped memory piece

	mov 	x22, x0

	add	x1, x0, GPFSEL_OFFSET // x1 = offset to GPFSEL
	ldr	w2, [x1] // save contents of GPFSEL to w2

	and	w2, w2, ~(7<<BIT_OFFSET)
	str	w2, [x1]

read: 	// read loop
	add	x1, x0, GPLEV_OFFSET // offset to GPLEV
	ldr	w2, [x1]
	lsr 	w2, w2, (BIT_OFFSET%32)
	//and 	w2, w2, 0xFF

	mov 	x8, 93
	mov 	x0, x2
	svc 	0


	
	mov	x8, 64	
	mov 	x0, 1
	mov 	x1, LOAD_ADDRESS
	add 	x1, x1, off
	add	x1, x1, x2
	mov 	x2, 4
	svc	0
	
	b 	read

gpiomem_path: 
	.asciz "/dev/gpiomem"
off:
	.asciz "off\n"
on:
	.asciz "on \n"

//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INCLUDES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	// external assembly files will be included here

//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

END:	// address label representing the end of our program

mapped_memory: .space gpiomem_length

