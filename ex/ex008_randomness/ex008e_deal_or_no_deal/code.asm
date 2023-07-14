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

%include "lib/math/rand/rand_int_array.asm"
; void rand_int_array(long* {rdi}, int {rsi}, uint {rdx}, 
;	signed long {rcx}, signed long {r8});

%include "lib/io/print_int_d.asm"
; void print_int_d(int {rdi}, int {rsi});

%include "lib/io/print_chars.asm"
; void print_chars(int {rdi}, char* {rsi}, int {rdx});

%include "lib/io/read_chars.asm"
; int {rax} read_chars(int {rdi}, char* {rsi}, int {rdx});

%include "lib/io/parse_int.asm"
; signed long {rax} strlen(char* {rdi});

%include "lib/io/strlen.asm"
; int {rax} strlen(char* {rdi});

%include "lib/io/ansi_move_cursor.asm"
; void ansi_move_cursor(int {rdi}, int {rsi}, int {rdx});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRINT_CASES:
	; clear screen
	mov rdi,SYS_STDOUT
	mov rsi,CLEAR_SCREEN
	mov rdx,4
	call print_chars

	; cursor on top left
	mov rsi,1
	mov rdx,1
	call ansi_move_cursor

	xor r15,r15
.loop:
	; print '['
	mov rsi,.grammar
	mov rdx,1
	call print_chars

	; print case number
	mov rsi,r15 
	call print_int_d

	; print ']'
	mov rsi,.grammar+1
	mov rdx,1
	call print_chars

	; print ': '
	mov rsi,.grammar+2
	mov rdx,2
	call print_chars

	; determine if we know the value
	mov rsi,[STATUSES+8*r15]
	cmp r15,rbx
	je .selected_value
	test rsi,rsi
	jns .known_value
.unknown_value:
	; print '???'
	mov rsi,.grammar+4
	mov rdx,3
	call print_chars
	jmp .value_printed
.known_value:
	; print '$'
	mov rsi,.grammar+9
	mov rdx,1
	call print_chars
	; print value
	mov rsi,[STATUSES+8*r15]
	mov rdx,5
	cmp rsi,1000	; if value is <1000, do green color
	jl .green
	cmp rsi,100000	; if value is <100000, do yellow color
	jl .yellow
	mov rsi,RED	; otherwise, do red color
	jmp .print_value
.yellow:
	mov rsi,YELLOW
	jmp .print_value
.green:
	mov rsi,GREEN
.print_value:
	call print_chars
	mov rsi,[STATUSES+8*r15]
	call print_int_d
	cmp rsi,9	; if we are 1-digit number
	jg .value_printed
	mov rsi,.grammar+3	; print a trailing space
	mov rdx,1
	call print_chars
	jmp .value_printed
.selected_value:
	; print "YOURS"
	mov rsi,.grammar+10
	mov rdx,14
	call print_chars
.value_printed:
	; reset color
	mov rsi,.grammar+20
	mov rdx,4
	call print_chars
	test r15,1	; check if we are a multiple of 2
	jz .print_tab
.print_newline:	; print newline
	mov rsi,.grammar+8
	mov rdx,1
	call print_chars
	jmp .trailing_grammar_printed
.print_tab:	; print tab
	mov rsi,.grammar+7
	mov rdx,1
	call print_chars
.trailing_grammar_printed:
	; loop until done
	inc r15
	cmp r15,26
	jl .loop
	ret
.grammar:
	db `[]: ???\t\n$\e[36mYOURS\e[0m`

PRINT_INFO:
	; print instructions
	mov rdi,SYS_STDOUT
	mov rsi,.grammar
	mov rdx,119
	call print_chars

	; print appraisal
	mov rsi,rbp
	call print_int_d

	; reset font color and newline
	mov rsi,.grammar+119
	mov rdx,5
	call print_chars

	ret

.grammar:
	db `\ntype a number 0-26 to open a case`
	db `\ntype 'w' to walk away with your case (& quit)`
	db `\ntype 's' to sell your case for: \e[35m$\e[0m\n`

START:
	; random integer array for shuffling	
	mov rdi,SHUFFLE_ARRAY
	xor rsi,rsi
	mov rdx,26
	mov rcx,0
	mov r8,25
	call rand_int_array

	; fisher-yates shuffle the cases
	xor r15,r15
.shuffle_loop:
	mov rax,[SHUFFLE_ARRAY+8*r15]	; {rax} contains i'th random number
	mov rbx,[CASES+8*rax]	; {rbx} contains selected case number
	mov rcx,[CASES+8*r15]	; {rcx} contains the i'th case number
	mov [CASES+8*rax],rcx	; swap those 2 cases
	mov [CASES+8*r15],rbx
	inc r15
	cmp r15,26
	jl .shuffle_loop

	xor rbp,rbp		; current appraisal in {rbp}

.pick_case:

	; selected case in {rbx}
	mov rbx,-1

	; clear screen
	mov rdi,SYS_STDOUT
	mov rsi,CLEAR_SCREEN
	mov rdx,4
	call print_chars	

	; print out cases
	call PRINT_CASES

	; ask user to pick one
	mov rdi,SYS_STDOUT
	mov rsi,PICK_A_CASE
	mov rdx,19
	call print_chars

	call print_buffer_flush

	mov rdi,SYS_STDIN
	mov rsi,READ_BUFFER
	mov rdx,4
	call read_chars

	; parse user selection
	mov rdi,READ_BUFFER
	call strlen
	dec rax
	mov byte [rax+READ_BUFFER],0	; remove trailing newline
	call parse_int

	; only accept valid cases
	cmp rax,0
	jl .pick_case
	cmp rax,25
	jg .pick_case

	mov rbx,rax	; save case selection in rbx

	; game loop
.game_loop:

	; compute the expected value
	mov rax,3418416	; sum of all the cases
	xor r15,r15
	mov r14,26	; number of unknown cases
.expected_value_loop:
	mov rcx,[STATUSES+8*r15]	; status in {rcx}
	test rcx,rcx
	js .unknown_case
	sub rax,rcx
	dec r14
.unknown_case:
	inc r15
	cmp r15,26
	jl .expected_value_loop
	cmp r14,1	; if only 1 case left, walk away
	jbe .walk_away
	xor rdx,rdx
	div r14
	mov rbp,rax	; appraisal saved in {rbp}

	; print stuff
	call PRINT_CASES
	call PRINT_INFO
	
	; flush buffer
	mov rdi,SYS_STDOUT
	call print_buffer_flush

	; get user input	
	mov rdi,SYS_STDIN
	mov rsi,READ_BUFFER
	mov rdx,4
	call read_chars

	; process sales
	cmp byte [READ_BUFFER],`s`
	je .sell_case

	; process walk-aways
	cmp byte [READ_BUFFER],`w`
	je .walk_away

	; parse user selection
	mov rdi,READ_BUFFER
	call strlen
	dec rax
	mov byte [rax+READ_BUFFER],0	; remove trailing newline
	call parse_int

	; only accept valid cases
	cmp rax,rbx	; cant pick your own case
	je .game_loop
	cmp rax,0
	jl .game_loop
	cmp rax,25
	jg .game_loop

	; process case selected 0-25 in {rax}
	mov rcx,[CASES+8*rax]
	mov rcx,[VALUES+8*rcx]
	mov [STATUSES+8*rax],rcx

	jmp .game_loop

.sell_case:

	; clear screen
	mov rdi,SYS_STDOUT
	mov rsi,CLEAR_SCREEN
	mov rdx,4
	call print_chars

	; cursor on top left
	mov rsi,1
	mov rdx,1
	call ansi_move_cursor

	; print sell-case text
	mov rsi,SELL_CASE
	mov rdx,46
	call print_chars

	mov rsi,rbp	
	call print_int_d

	; print FYI text
	mov rsi,SELL_CASE+46
	mov rdx,31
	call print_chars
	
	mov rcx,[CASES+8*rbx]
	mov rsi,[VALUES+8*rcx]
	call print_int_d

	mov rsi,SELL_CASE+77
	mov rdx,12
	call print_chars

	jmp .exit

.walk_away:

	; clear screen
	mov rdi,SYS_STDOUT
	mov rsi,CLEAR_SCREEN
	mov rdx,4
	call print_chars

	; cursor on top left
	mov rsi,1
	mov rdx,1
	call ansi_move_cursor

	; print walk-away text
	mov rsi,WALK_AWAY
	mov rdx,44
	call print_chars

	mov rcx,[CASES+8*rbx]
	mov rsi,[VALUES+8*rcx]
	call print_int_d

	mov rsi,WALK_AWAY+44
	mov rdx,6
	call print_chars

.exit:
	
	; flush print buffer
	call print_buffer_flush	

	; exit
	xor dil,dil
	call exit	

PICK_A_CASE:
	db `\npick a case 0-25:\n`

WALK_AWAY:
	db `Congratulations, you walked away with \e[36m$\e[0m.\n`

SELL_CASE:
	db `Congratulations, you sold your case for \e[35m$\e[0m.\n`
	db `FYI, your case had \e[36m$\e[0m in it.\n`

READ_BUFFER:
	times 4 db 0

CLEAR_SCREEN:
	db `\e[2J`

RED:
	db `\e[31m`

GREEN:
	db `\e[32m`

YELLOW:
	db `\e[33m`

SHUFFLE_ARRAY:
	times 26 dq 0

CASES:
	dq 0,1,2,3,4,5,6,7,8,9,10,11,12,13
	dq 14,15,16,17,18,19,20,21,22,23,24,25

STATUSES: ; -1 for unknown, otherwise contains the known value
	times 26 dq -1

VALUES:	; 26 case values, in dollars
	dq 0
	dq 1
	dq 5
	dq 10
	dq 25
	dq 50
	dq 75
	dq 100
	dq 200
	dq 300
	dq 400
	dq 500
	dq 750
	dq 1000
	dq 5000
	dq 10000
	dq 25000
	dq 50000
	dq 75000
	dq 100000
	dq 200000
	dq 300000
	dq 400000
	dq 500000
	dq 750000
	dq 1000000

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
