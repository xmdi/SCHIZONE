;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define LOAD_ADDRESS 0x00020000 ; pretty much any number >0 works
%define CODE_SIZE END-(LOAD_ADDRESS+0x78) ; everything beyond HEADER is code
%define PRINT_BUFFER_SIZE 4096

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
	dq CODE_SIZE+PRINT_BUFFER_SIZE ; size (bytes) of segment in memory
	dq 0x0000000000000000 ; alignment (doesn't matter, only 1 segment)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INCLUDES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%include "syscalls.asm"	; requires syscall listing for your OS in lib/sys/	

%include "lib/io/print_chars.asm"
; void print_chars(int {rdi}, char* {rsi}, int {rdx});

%include "lib/io/read_chars.asm"
; int {rax} read_chars(int {rdi}, char* {rsi}, int {rdx});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:
	
	; save old termios
	mov rax,SYS_IOCTL
	mov rdi,SYS_STDIN
	mov rsi,SYS_TCGETA
	mov rdx,OLD
	syscall

	; save "new" termios placeholder
	mov rax,SYS_IOCTL
	mov rdi,SYS_STDIN
	mov rsi,SYS_TCGETA
	mov rdx,NEW
	syscall

	; adjust "new" termios for raw mode
	and dword [NEW],~(SYS_IGNBRK+SYS_BRKINT+SYS_PARMRK+SYS_ISTRIP+SYS_INLCR+SYS_IGNCR+SYS_ICRNL+SYS_IXON)
	and dword [NEW+4],~SYS_OPOST
	and dword [NEW+8],~(SYS_CSIZE+SYS_PARENB)
	or dword [NEW+8],SYS_CS8
	and dword [NEW+12],~(SYS_ICANON+SYS_ECHO+SYS_ECHONL+SYS_ISIG+SYS_IEXTEN)

	; set terminal to "new" termios for raw mode
	mov rax,SYS_IOCTL
	mov rdi,SYS_STDIN
	mov rsi,SYS_TCSETA
	mov rdx,NEW
	syscall

; this loop parses 4 bytes of input forever
.loop:
	mov dword [READ_BUFFER],0 ; clear 4 bytes in the read buffer

	mov rdi,SYS_STDIN
	mov rsi,READ_BUFFER
	mov rdx,4
	call read_chars	; read 4 bytes into input buffer

	cmp dword [READ_BUFFER], 0x00415b1b ; 27, 91, 65, 0
	je .UP_ARROW_PRESSED
	
	cmp dword [READ_BUFFER], 0x00425b1b ; 27, 91, 66, 0
	je .DOWN_ARROW_PRESSED
	
	cmp dword [READ_BUFFER], 0x00435b1b ; 27, 91, 67, 0
	je .RIGHT_ARROW_PRESSED
	
	cmp dword [READ_BUFFER], 0x00445b1b ; 27, 91, 68, 0
	je .LEFT_ARROW_PRESSED

	cmp byte [READ_BUFFER], 106
	je .J_PRESSED

	cmp byte [READ_BUFFER], 86
	je .CAP_V_PRESSED

	cmp byte [READ_BUFFER], 13
	je .ENTER_PRESSED

	cmp byte [READ_BUFFER], 32
	je .SPACE_PRESSED
	
	cmp byte [READ_BUFFER], 27
	je .done

	cmp byte [READ_BUFFER], 113 
	je .done

	jmp .loop


.UP_ARROW_PRESSED:
	mov rdi,SYS_STDOUT
	mov rsi,up_arrow_pressed
	mov rdx,26
	call print_chars
	call print_buffer_flush
	jmp .loop

.DOWN_ARROW_PRESSED:
	mov rdi,SYS_STDOUT
	mov rsi,down_arrow_pressed
	mov rdx,28
	call print_chars
	call print_buffer_flush
	jmp .loop

.RIGHT_ARROW_PRESSED:
	mov rdi,SYS_STDOUT
	mov rsi,right_arrow_pressed
	mov rdx,29
	call print_chars
	call print_buffer_flush
	jmp .loop

.LEFT_ARROW_PRESSED:
	mov rdi,SYS_STDOUT
	mov rsi,left_arrow_pressed
	mov rdx,28
	call print_chars
	call print_buffer_flush
	jmp .loop

.J_PRESSED:
	mov rdi,SYS_STDOUT
	mov rsi,j_pressed
	mov rdx,15
	call print_chars
	call print_buffer_flush
	jmp .loop

.CAP_V_PRESSED:
	mov rdi,SYS_STDOUT
	mov rsi,cap_v_pressed
	mov rdx,19
	call print_chars
	call print_buffer_flush
	jmp .loop

.SPACE_PRESSED:
	mov rdi,SYS_STDOUT
	mov rsi,space_pressed
	mov rdx,19
	call print_chars
	call print_buffer_flush
	jmp .loop

.ENTER_PRESSED:
	mov rdi,SYS_STDOUT
	mov rsi,enter_pressed
	mov rdx,19
	call print_chars
	call print_buffer_flush
	jmp .loop

.done:
	; restore old termios
	mov rax,SYS_IOCTL
	mov rdi,SYS_STDIN
	mov rsi,SYS_TCSETA
	mov rdx,OLD
	syscall

	; flush print buffer
	call print_buffer_flush

	xor dil,dil
	call exit	

align 64
NEW:
	times 48 db 0
OLD:
	times 48 db 0
READ_BUFFER:
	times 4 db 0

left_arrow_pressed:
	db `you pressed the left arrow\r\n`
right_arrow_pressed:
	db `you pressed the right arrow\r\n`
up_arrow_pressed:
	db `you pressed the up arrow\r\n`
down_arrow_pressed:
	db `you pressed the down arrow\r\n`
j_pressed:
	db `you pressed j\r\n`
cap_v_pressed:
	db `you pressed cap v\r\n`
space_pressed:
	db `you pressed space\r\n`
enter_pressed:
	db `you pressed enter\r\n`

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
