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

%include "lib/io/svg/scatter_plot.asm"
; void scatter_plot(uint {rdi}, struct* {rsi});

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

	; write scatter plot to SVG file
	mov rdi,rax			; output file descriptor
	mov rsi,.plot_structure		; structure start address
	call scatter_plot

	; close file
	call file_close

	; exit
	xor dil,dil
	call exit	

.filename:
	db `inside_job.svg`,0

.title:
	db `Height of 1 &amp; 2 WTC`,0

.xlabel:
	db `Days after August 1, 2001`,0

.ylabel:
	db `Feet`,0

.plot_structure:
	dq .title; address of null-terminated title string {*+0}
	dq .xlabel; address of null-terminated x-label string {*+8}
	dq .ylabel; address of null-terminated y-label string {*+16}
	dq .data1; address of linked list for datasets {*+24}
	dw 400; plot width (px) {*+32}
	dw 200; plot height (px) {*+34}
	dw 5; plot margins (px) {*+36}
	dq 0.0; x-min (double) {*+38}
	dq 60.0; x-max (double) {*+46}
	dq 0.0; y-min (double) {*+54}
	dq 1500.0; y-max (double) {*+62}
	dw 100; legend left x-coordinate (px) {*+70}
	dw 120; legend top y-coordinate (px) {*+72}
	dw 70; legend width (px) {*+74}
	dd 0xFFFFFF; #XXXXXX RGB background color {*+76}
	dd 0x000000; #XXXXXX RGB axis color {*+80}
	dd 0x000000; #XXXXXX RGB font color {*+84}
	db 7; number of major x-ticks {*+88}
	db 4; number of major y-ticks {*+89}
	db 4; minor subdivisions per x-tick {*+90}
	db 4; minor subdivisions per y-tick {*+91}
	db 2; significant digits on x values {*+92}
	db 6; significant digits on y values {*+93}
	db 14; title font size (px) {*+94}
	db 5; vertical margin below title (px) {*+95}
	db 12; axis label font size (px) {*+96}
	db 8; tick & legend label font size (px) {*+97}
	db 5; horizontal margin right of y-tick labels (px) {*+98}
	db 5; vertical margin above x-tick labels (px) {*+99}
	db 2; grid major stroke thickness (px) {*+100}
	db 1; grid minor stroke thickness (px) {*+101}
	db 40; width for y-axis ticks (px) {*+102}
	db 20; height for x-axis ticks (px) {*+103}
	db 0x3F; flags: {*+104}
		; bit 0 (LSB)	= show title?
		; bit 1		= show x-label?
		; bit 2		= show y-label?
		; bit 3		= draw grid?
		; bit 4		= show tick labels?
		; bit 5		= draw legend?

.data1:
	dq .data2; address of next dataset in linked list {*+0}
	dq .wtc1; address of null-terminated label string {*+8}
	dq .days; address of first x-coordinate {*+16}
	dw 0; extra stride between x-coord elements {*+24}
	dq .wtc1_y; address of first y-coordinate {*+26}
	dw 0; extra stride between y-coord elements {*+34}
	dd 61; number of elements {*+36}
	dd 0xFF0000; #XXXXXX RGB marker color {*+40}
	dd 0xFF0000; #XXXXXX RGB line color {*+44}
	dd 0x000000; #XXXXXX RGB fill color {*+48}
	db 3; marker size (px) {*+52}
	db 2; line thickness (px) {*+53}
	db 0; fill opacity (%) {*+54}
	db 0x13; flags: {*+55}
		; bit 0 (LSB)	= point marker?
		; bit 1		= connecting lines?
		; bit 2		= dashed line? (bit 1 must be set)
		; bit 3		= fill?
		; bit 4		= include in legend?
		; bits 6-5	= 00 = no curves
		;		= 01 = quadratic bezier
		;		= 10 = cubic bezier
		;		= 11 = arc

.data2:
	dq 0; address of next dataset in linked list {*+0}
	dq .wtc2; address of null-terminated label string {*+8}
	dq .days; address of first x-coordinate {*+16}
	dw 0; extra stride between x-coord elements {*+24}
	dq .wtc2_y; address of first y-coordinate {*+26}
	dw 0; extra stride between y-coord elements {*+34}
	dd 61; number of elements {*+36}
	dd 0x0000FF; #XXXXXX RGB marker color {*+40}
	dd 0x0000FF; #XXXXXX RGB line color {*+44}
	dd 0x000000; #XXXXXX RGB fill color {*+48}
	db 2; marker size (px) {*+52}
	db 1; line thickness (px) {*+53}
	db 0; fill opacity (%) {*+54}
	db 0x13; flags: {*+55}
		; bit 0 (LSB)	= point marker?
		; bit 1		= connecting lines?
		; bit 2		= dashed line? (bit 1 must be set)
		; bit 3		= fill?
		; bit 4		= include in legend?
		; bits 6-5	= 00 = no curves
		;		= 01 = quadratic bezier
		;		= 10 = cubic bezier
		;		= 11 = arc


.wtc1: ; legend entry for first line
	db `1 WTC\0`

.wtc2: ; legend entry for second line
	db `2 WTC\0`

.wtc1_y: ; y values for first line
	times 41 dq 1368.0
	times 20 dq 0.0

.wtc2_y: ; y values for second line
	times 41 dq 1362.0
	times 20 dq 0.0

.days:	; x values for both lines
	dq 0.0,1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0,16.0,17.0,18.0,19.0
	dq 20.0,21.0,22.0,23.0,24.0,25.0,26.0,27.0,28.0,29.0,30.0,31.0,32.0,33.0,34.0,35.0,36.0,37.0,38.0,39.0
	dq 40.0,41.0,42.0,43.0,44.0,45.0,46.0,47.0,48.0,49.0,50.0,51.0,52.0,53.0,54.0,55.0,56.0,57.0,58.0,59.0,60.0

END:

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
