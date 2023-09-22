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

%include "lib/io/file_open.asm"
; int {rax} file_open(char* {rdi}, int {rsi}, int {rdx});

%include "lib/io/file_close.asm"
; int {rax} file_close(int {rdi});

%include "lib/io/html/print_html.asm"
; void print_html(int {rdi}, struct* {rsi});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:

	; open file
	mov rdi,.filename
	mov rsi,SYS_READ_WRITE+SYS_CREATE_FILE+SYS_TRUNCATE
	mov rdx,SYS_DEFAULT_PERMISSIONS
	call file_open	; file descriptor in {rax}

	; write report to HTML file
	mov rdi,rax			; output file descriptor
	mov rsi,.title_structure	; structure linked list start address
	call print_html

	; close file
	call file_close

	; exit
	xor dil,dil
	call exit	

.filename:
	db `Q3_2023_Financial_Report.html`,0

.title:
	db `Q3 2023 Financial Report`,0

.author:
	db `presented by Matthew (CFO)`,0

.date_accessed_code:
	db `<p>Accessed on <script type="text/javascript">document.write(new Date().toLocaleString() );</script></p>`,0

.title_structure:
	dq .author_structure; address of next item in linked list
	db 1 ; type of item (0-7)
	dq .title ; address of null-terminated string of text to print

.author_structure:
	dq .date_accessed_structure; address of next item in linked list
	db 2 ; type of item (0-7)
	dq .author ; address of null-terminated string of text to print

.date_accessed_structure:
	dq .horizontal_divider_1; address of next item in linked list
	db 7 ; type of item (0-7)
	dq .date_accessed_code ; address of null-terminated string of text to print

.horizontal_divider_1:
	dq 0 ; address of next item in linked list
	db 8 ; type of item (0-7)
	

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
