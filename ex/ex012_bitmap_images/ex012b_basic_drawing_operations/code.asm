;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define LOAD_ADDRESS 0x00020000 ; pretty much any number >0 works
%define CODE_SIZE END-(LOAD_ADDRESS+0x78) ; everything beyond HEADER is code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;HEADER;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BITS 64
org LOAD_ADDRESS
ELF_HEADER:
	db 0x7F,"ELF" ; magic number to indicate ELF file
	db 0x02 ; 0x1 for 32-bit, 0x2 for 64-bit
	db 0x01 ; 0x1 for little endian, 0x2 for big endian
	db 0x01 ; 0x1 for current version of ELF
	db 0x09 ; 0x9 for FreeBSD, 0x3 for Linux (doesn't seem to matter)
	db 0x00 ; ABI version (ignored?)
	times 7 db 0x00 ; 7 padding bytes
	dw 0x0002 ; executable file
	dw 0x003E ; AMD x86-64 
	dd 0x00000001 ; version 1
	dq START ; entry point for our program
	dq 0x0000000000000040 ; 0x40 offset from ELF_HEADER to PROGRAM_HEADER
	dq 0x0000000000000000 ; section header offset (we don't have this)
	dd 0x00000000 ; unused flags
	dw 0x0040 ; 64-byte size of ELF_HEADER
	dw 0x0038 ; 56-byte size of each program header entry
	dw 0x0001 ; number of program header entries (we have one)
	dw 0x0000 ; size of each section header entry (none)
	dw 0x0000 ; number of section header entries (none)
	dw 0x0000 ; index in section header table for section names (waste)
PROGRAM_HEADER:
	dd 0x00000001 ; 0x1 for loadable program segment
	dd 0x00000007 ; read/write/execute flags
	dq 0x0000000000000078 ; offset of code start in file image (0x40+0x38)
	dq LOAD_ADDRESS+0x78 ; virtual address of segment in memory
	dq 0x0000000000000000 ; physical address of segment in memory (ignored?)
	dq CODE_SIZE ; size (bytes) of segment in file image
	dq CODE_SIZE ; size (bytes) of segment in memory
	dq 0x0000000000000000 ; alignment (doesn't matter, only 1 segment)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INCLUDES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%include "syscalls.asm"	; requires syscall listing for your OS in lib/sys/	

%include "lib/io/file_open.asm"
; int {rax} file_open(char* {rdi}, int {rsi}, int {rdx});

%include "lib/io/file_close.asm"
; int {rax} file_close(int {rdi});

%include "lib/io/bitmap/write_bitmap.asm"
; void write_bitmap(int {rdi}, void* {rsi}, int {edx}, int {ecx});

%include "lib/io/bitmap/set_pixel.asm"
; void set_pixel(void* {rdi}, int {esi}, int {edx}, int {r8d}, int {r9d});

%include "lib/io/bitmap/set_line.asm"
; void set_line(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});

%include "lib/io/bitmap/get_pixel.asm"
; int {rax} get_pixel(void* {rdi}, int {esi}, int {edx}, int {r8d});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:

	; open/create the bitmap file
	mov rdi,.FILENAME 		; filename in {rdi}
	mov rsi,SYS_READ_WRITE+SYS_CREATE_FILE	; put R/W/CREATE flags in {rsi}
	mov rdx,SYS_DEFAULT_PERMISSIONS	; default permissions in {rdx}
	call file_open			; call function to open file
	mov rbx,rax			; {rbx} contains new file descriptor

	; set a pixel at (40,20) to blue
	mov rdi,.IMAGE
	mov esi,0xFF0000FF
	mov edx,64
	mov ecx,48
	mov r8d,40
	mov r9d,20
	call set_pixel

	; get pixel value from (40,20)
	mov rdi,.IMAGE
	mov esi,64
	mov edx,48
	mov ecx,40
	mov r8d,20
	call get_pixel	; pixel value in {rax}

	add eax,0xFF00	; change color from blue to cyan

	; set a pixel at (41,21) to cyan
	mov rdi,.IMAGE
	mov esi,eax
	mov edx,64
	mov ecx,48
	mov r8d,41
	mov r9d,21
	call set_pixel

	; set a white line
	mov rdi,.IMAGE
	mov esi,0xFFFFFFFF
	mov edx,64
	mov ecx,48
	mov r8d,0;5
	mov r9d,1;2
	mov r10d,6;40
	mov r11d,4;15
	call set_line

	; write the bitmap	
	mov rdi,rbx
	mov rsi,.IMAGE
	mov edx,64
	mov ecx,48
	call write_bitmap

	; close the bitmap file
	mov rdi,rax
	call file_close

	; exit
	xor dil,dil
	call exit	

.FILENAME:
	db `kek.bmp\0`

.IMAGE:	; space for a 640x480 image
	times 64*48*4 dw 0x00

END:
