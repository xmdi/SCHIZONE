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
	db `first_catholic_president.svg`,0

.title:
	db `John F. Kennedy Mean Annual Heart Rate`,0

.xlabel:
	db `Anno Domini`,0

.ylabel:
	db `Beats per Minute`,0

.plot_structure:
	dq .title; address of null-terminated title string {*+0}
	dq .xlabel; address of null-terminated x-label string {*+8}
	dq .ylabel; address of null-terminated y-label string {*+16}
	dq .dataset_structure; address of linked list for datasets {*+24}
	dw 400; plot width (px) {*+32}
	dw 200; plot height (px) {*+34}
	dw 5; plot margins (px) {*+36}
	dq 1900.0; x-min (double) {*+38}
	dq 2000.0; x-max (double) {*+46}
	dq 0.0; y-min (double) {*+54}
	dq 100.0; y-max (double) {*+62}
	dw 0; legend left x-coordinate (px) {*+70}
	dw 0; legend top y-coordinate (px) {*+72}
	dw 0; legend width (px) {*+74}
	dd 0xFFFFFF; #XXXXXX RGB background color {*+76}
	dd 0x000000; #XXXXXX RGB axis color {*+80}
	dd 0x000000; #XXXXXX RGB font color {*+84}
	db 11; number of major x-ticks {*+88}
	db 5; number of major y-ticks {*+89}
	db 2; minor subdivisions per x-tick {*+90}
	db 2; minor subdivisions per y-tick {*+91}
	db 4; significant digits on x values {*+92}
	db 2; significant digits on y values {*+93}
	db 14; title font size (px) {*+94}
	db 5; vertical margin below title (px) {*+95}
	db 12; axis label font size (px) {*+96}
	db 8; tick & legend label font size (px) {*+97}
	db 5; horizontal margin right of y-tick labels (px) {*+98}
	db 5; vertical margin above x-tick labels (px) {*+99}
	db 2; grid major stroke thickness (px) {*+100}
	db 1; grid minor stroke thickness (px) {*+101}
	db 30; width for y-axis ticks (px) {*+102}
	db 30; height for x-axis ticks (px) {*+103}
	db 0x1F; flags: {*+104}
		; bit 0 (LSB)	= show title?
		; bit 1		= show x-label?
		; bit 2		= show y-label?
		; bit 3		= draw grid?
		; bit 4		= show tick labels?
		; bit 5		= draw legend?

.dataset_structure:
	dq 0; address of next dataset in linked list {*+0}
	dq 0; address of null-terminated label string {*+8}
	dq .year; address of first x-coordinate {*+16}
	dw 0; extra stride between x-coord elements {*+24}
	dq .bpm; address of first y-coordinate {*+26}
	dw 0; extra stride between y-coord elements {*+34}
	dd 101; number of elements {*+36}
	dd 0xFF0000; #XXXXXX RGB marker color {*+40}
	dd 0xFF0000; #XXXXXX RGB line color {*+44}
	dd 0x000000; #XXXXXX RGB fill color {*+48}
	db 2; marker size (px) {*+52}
	db 2; line thickness (px) {*+53}
	db 0; fill opacity (%) {*+54}
	db 0x03; flags: {*+55}
		; bit 0 (LSB)	= point marker?
		; bit 1		= connecting lines?
		; bit 2		= dashed line? (bit 1 must be set)
		; bit 3		= fill?
		; bit 4		= include in legend?
		; bits 6-5	= 00 = no curves
		;		= 01 = quadratic bezier
		;		= 10 = cubic bezier
		;		= 11 = arc

.bpm:	; y values
	times 17 dq 0.0
	dq 33.0
	times 45 dq 80.0
	dq 72.0
	times 37 dq 0.0

.year:	; x values
	dq 1900.0,1901.0,1902.0,1903.0,1904.0,1905.0,1906.0,1907.0,1908.0,1909.0
	dq 1910.0,1911.0,1912.0,1913.0,1914.0,1915.0,1916.0,1917.0,1918.0,1919.0
	dq 1920.0,1921.0,1922.0,1923.0,1924.0,1925.0,1926.0,1927.0,1928.0,1929.0
	dq 1930.0,1931.0,1932.0,1933.0,1934.0,1935.0,1936.0,1937.0,1938.0,1939.0
	dq 1940.0,1941.0,1942.0,1943.0,1944.0,1945.0,1946.0,1947.0,1948.0,1949.0
	dq 1950.0,1951.0,1952.0,1953.0,1954.0,1955.0,1956.0,1957.0,1958.0,1959.0
	dq 1960.0,1961.0,1962.0,1963.0,1964.0,1965.0,1966.0,1967.0,1968.0,1969.0
	dq 1970.0,1971.0,1972.0,1973.0,1974.0,1975.0,1976.0,1977.0,1978.0,1979.0
	dq 1980.0,1981.0,1982.0,1983.0,1984.0,1985.0,1986.0,1987.0,1988.0,1989.0
	dq 1990.0,1991.0,1992.0,1993.0,1994.0,1995.0,1996.0,1997.0,1998.0,1999.0
	dq 2000.0

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
