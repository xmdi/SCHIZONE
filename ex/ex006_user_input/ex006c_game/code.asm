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

%include "lib/sys/toggle_raw_mode.asm"
; int {rax} toggle_raw_mode(int {rdi});

%include "lib/io/print_chars.asm"
; void print_chars(int {rdi}, char* {rsi}, int {rdx});

%include "lib/io/ansi_move_cursor.asm"
; void ansi_move_cursor(int {rdi}, int {rsi}, int {rdx});

%include "lib/math/rand/rand_int.asm"
; signed long {rax} rand_int(signed long {rdi}, signed long {rsi});

%include "lib/io/file_open.asm"
; int {rax} file_open(char* {rdi}, int {rsi}, int {rdx});

%include "lib/io/file_close.asm"
; int {rax} file_close(int {rdi});

%include "lib/io/parse_int.asm"
; signed long {rax} parse_int(char* {rdi});

%include "lib/io/strlen.asm"
; int {rax} strlen(char* {rdi});

%include "lib/io/read_chars.asm"
; int {rax} read_chars(int {rdi}, char* {rsi}, int {rdx});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:

	mov rdi,HIGH_SCORE_FILE
	mov rsi,SYS_READ_WRITE+SYS_CREATE_FILE
	mov rdx,SYS_DEFAULT_PERMISSIONS
	call file_open
	mov rbp,rax

	mov rdi,rbp
	mov rsi,READ_BUFFER
	mov rdx,32
	call read_chars

	mov rdi,READ_BUFFER
	call strlen

	test rax,rax	; check if file existed
	jnz .high_score_file_exists

	mov rdi,rbp
	xor rsi,rsi
	call print_int_d
	call print_buffer_flush

	mov rsi,PREP+1
	mov rdx,1	
	call print_chars

	call print_buffer_flush

	call file_close
	
	xor rbx,rbx	
	jmp .PREP_MAIN_MENU

.high_score_file_exists:

	dec rax
	mov byte [rax+READ_BUFFER],0
	call parse_int
	mov rbx,rax 

.PREP_MAIN_MENU:

	xor rdi,rdi		; flag to enable raw input mode
	call toggle_raw_mode

MAIN_MENU:

	; clear screen
	mov rdi,SYS_STDOUT
	mov rsi,CLEAR_SCREEN
	mov rdx,4
	call print_chars

	mov rsi,HIDE_CURSOR
	mov rdx,6
	call print_chars

	mov rsi,1
	mov rdx,3
	call ansi_move_cursor

	mov rsi,.GAME_TITLE
	mov rdx,.MENU_CURSOR-.GAME_TITLE
	call print_chars

	mov rsi,.HIGH_SCORE_GRAMMAR
	mov rdx,24
	call print_chars

	mov rsi,rbx
	call print_int_d

	mov rsi,.HIGH_SCORE_GRAMMAR+24
	mov rdx,2
	call print_chars

	mov rsi,.NEW_GAME_GRAMMAR
	mov rdx,30
	call print_chars

	mov rsi,.QUIT_GAME_GRAMMAR
	mov rdx,30
	call print_chars

	mov rsi,.CLEAR_SCORE_GRAMMAR
	mov rdx,30
	call print_chars

	call print_buffer_flush	
	
	xor r8,r8	; menu selection
	
	call .UPDATE_MENU

.main_menu_loop:	
	mov dword [READ_BUFFER],0 ; clear 4 bytes in the read buffer
	
	mov rdi,SYS_STDIN
	mov rsi,READ_BUFFER
	mov rdx,4
	call read_chars	; read 4 bytes into input buffer

	cmp dword [READ_BUFFER], 0x00415b1b ; 27, 91, 65, 0
	je .UP_ARROW_PRESSED
	
	cmp dword [READ_BUFFER], 0x00425b1b ; 27, 91, 66, 0
	je .DOWN_ARROW_PRESSED
	
	cmp byte [READ_BUFFER], 13 ; ENTER
	je .SELECT

	cmp byte [READ_BUFFER], 32 ; SPACE
	je .SELECT

	jmp .main_menu_loop

.UP_ARROW_PRESSED:
	call .CLEAR_CURSOR
	dec r8
	jns .no_upward_loop_over
	mov r8,2
.no_upward_loop_over:
	jmp .UPDATE_MENU

.DOWN_ARROW_PRESSED:
	call .CLEAR_CURSOR
	inc r8
	cmp r8,3
	jl .no_downward_loop_over
	xor r8,r8
.no_downward_loop_over:
	jmp .UPDATE_MENU

.CLEAR_CURSOR:
	mov rsi,34
	mov rdx,r8
	add rdx,21
	call ansi_move_cursor

	mov rsi,.MENU_CURSOR+10
	mov rdx,1
	call print_chars
	call print_buffer_flush
	
	ret

.UPDATE_MENU:
	mov rsi,34
	mov rdx,r8
	add rdx,21
	call ansi_move_cursor

	mov rsi,.MENU_CURSOR
	mov rdx,10
	call print_chars
	call print_buffer_flush

	jmp .main_menu_loop

.CLEAR_RECORD:
	xor rbx,rbx

	call print_buffer_flush

	mov rdi,HIGH_SCORE_FILE
	mov rsi,SYS_READ_WRITE+SYS_TRUNCATE
	mov rdx,SYS_DEFAULT_PERMISSIONS
	call file_open
	mov rbp,rax

	mov rdi,rbp
	xor rsi,rsi
	call print_int_d

	mov rsi,PREP+1
	mov rdx,1	
	call print_chars

	call print_buffer_flush

	call file_close

	mov rdi,SYS_STDOUT
	mov rsi,46
	mov rdx,20
	call ansi_move_cursor

	mov rsi,rbx
	call print_int_d

	mov rsi,.GAME_YEAR
	mov rdx,20
	call print_chars

	call print_buffer_flush

	jmp .main_menu_loop
	
.SELECT:
	cmp r8,0
	je GAME
	cmp r8,1
	je DONE
	cmp r8,2
	je .CLEAR_RECORD

.GAME_TITLE:
	db `\e[31m    _______  _______  ______   \e[32m  __    _  __   __  ______   _______  _______ \r\n`
	db `\e[31m   |       ||       ||      |  \e[32m |  |  | ||  | |  ||      | |       ||       |\r\n`
	db `\e[31m   |    ___||    ___||  _    | \e[32m |   |_| ||  | |  ||  _    ||    ___||    ___|\r\n`
	db `\e[31m   |   |___ |   |___ | | |   | \e[32m |       ||  |_|  || | |   ||   | __ |   |___ \r\n`
	db `\e[31m   |    ___||    ___|| |_|   | \e[32m |  _    ||       || |_|   ||   ||  ||    ___|\r\n`
	db `\e[31m   |   |    |   |___ |       | \e[32m | | |   ||       ||       ||   |_| ||   |___ \r\n`
	db `\e[31m   |___|    |_______||______|  \e[32m |_|  |__||_______||______| |_______||_______|\r\n`
	db `\n`
.GAME_YEAR:
	db `\e[33m                       _______  _______  _______  _______                    \r\n`
	db `                      |       ||  _    ||       ||       |                   \r\n`
	db `                      |___    || | |   ||___    ||___    |                   \r\n`
	db `                       ___|   || | |   | ___|   | ___|   |                   \r\n`
	db `                      |  _____|| |_|   ||  _____||___    |                   \r\n`
	db `                      | |_____ |       || |_____  ___|   |                   \r\n`
	db `                      |_______||_______||_______||_______|                   \r\n`
	db `\e[0m\n\n`

.MENU_CURSOR:
	db `\e[33m>\e[0m `
.HIGH_SCORE_GRAMMAR:
	db `\t\t\t         HIGH SCORE: \r\n`
.NEW_GAME_GRAMMAR:
	db `\t\t\t       |   NEW GAME     |\r\n`
.QUIT_GAME_GRAMMAR:
	db `\t\t\t       |   QUIT GAME    |\r\n`
.CLEAR_SCORE_GRAMMAR:
	db `\t\t\t       |   CLEAR RECORD |\r\n`
GAME:	
	; {r9} tracks number of unalived cia agents
	xor r9,r9

	; clear screen
	mov rdi,SYS_STDOUT
	mov rsi,CLEAR_SCREEN
	mov rdx,4
	call print_chars


RESTART:
	
	; hole position in ({r10},{r11})
	mov rdi,2
	mov rsi,39
	call rand_int
	mov r10,rax
	
	mov rdi,2
	mov rsi,19
	call rand_int
	mov r11,rax

.invalid_cia_position:
	; cia agent position in ({r12},{r13})
	mov rdi,3
	mov rsi,38
	call rand_int
	mov r12,rax
	
	mov rdi,3
	mov rsi,18
	call rand_int
	mov r13,rax

	cmp r12,r10
	jne .valid_cia_position

	cmp r13,r11
	jne .valid_cia_position

	jmp .invalid_cia_position

.valid_cia_position:	

.invalid_player_position:
	; player position in ({r14},{r15})

	mov rdi,2
	mov rsi,38
	call rand_int
	mov r14,rax
	
	mov rdi,2
	mov rsi,19
	call rand_int
	mov r15,rax

	cmp r14,r12
	jne .player_not_on_cia

	cmp r15,r13
	jne .player_not_on_cia

	jmp .invalid_player_position

.player_not_on_cia:

	cmp r14,r10
	jne .valid_player_position

	cmp r15,r11
	jne .valid_player_position

	jmp .invalid_player_position

.valid_player_position:	

	mov rdi,SYS_STDOUT
	xor rsi,rsi
	xor rdx,rdx
	call ansi_move_cursor

	; initial map
	mov rsi,MAP_TOP_BOT
	mov rdx,42
	call print_chars
	
	mov rcx,18
.map_loop:
	
	mov rsi,MAP_SIDES
	mov rdx,42
	call print_chars
	dec rcx
	jnz .map_loop

	mov rsi,MAP_TOP_BOT
	mov rdx,42
	call print_chars

	mov rsi,PREP
	mov rdx,2
	call print_chars

	xor rsi,rsi
	mov rdx,22
	call ansi_move_cursor

	mov rsi,CONTROL_GRAMMAR
	mov rdx,36
	call print_chars

	; draw initial player
	call .DRAW_PLAYER

	; draw initial cia_agent
	call .DRAW_CIA_AGENT

	; draw initial cia_agent
	call .DRAW_HOLE

	mov rsi,HIDE_CURSOR
	mov rdx,6
	call print_chars

	call print_buffer_flush

; this loop parses 4 bytes in input forever
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
	
	cmp byte [READ_BUFFER], 114 ; 'r'
	je RESTART

	cmp byte [READ_BUFFER], 27 ; ESCAPE
	je .LEAVE_GAME

	cmp byte [READ_BUFFER], 113 ; 'q'
	je .LEAVE_GAME

	jmp .loop

.LEAVE_GAME:
	cmp r9,rbx
	jle .leave_not_high_score
	mov rbx,r9

	call print_buffer_flush

	mov rdi,HIGH_SCORE_FILE
	mov rsi,SYS_READ_WRITE+SYS_TRUNCATE
	mov rdx,SYS_DEFAULT_PERMISSIONS
	call file_open
	mov rbp,rax

	mov rdi,rbp
	mov rsi,rbx
	call print_int_d

	mov rsi,PREP+1
	mov rdx,1	
	call print_chars

	call print_buffer_flush

	call file_close

	mov rdi,SYS_STDOUT

.leave_not_high_score:
	jmp MAIN_MENU 

.UP_ARROW_PRESSED:
	mov rdi,r14
	mov rsi,r15
	dec rsi
	call COLLISION_CHECK
	test rax,rax
	jz .UP_MOVE
	cmp rax,1	; wall hit, return to loop
	je .loop
	cmp rax,2	; hole hit, you dead
	je .FELL_IN_HOLE
	cmp rax,3	; cia agent hit
	je .UP_CIA
.UP_CIA:
	mov rdi,r14
	mov rsi,r15
	sub rsi,2
	call COLLISION_CHECK
	test rax,rax
	jz .CIA_UP_MOVE
	cmp rax,1	; wall hit, return to loop
	je .loop
	cmp rax,2	; hole hit, he dead
	je .CIA_IN_HOLE
.CIA_UP_MOVE:
	dec r13
	call .DRAW_CIA_AGENT
	call print_buffer_flush
.UP_MOVE:
	call .CLEAR_PLAYER
	dec r15
	call .DRAW_PLAYER	
	call print_buffer_flush
	jmp .loop

.DOWN_ARROW_PRESSED:
	mov rdi,r14
	mov rsi,r15
	inc rsi
	call COLLISION_CHECK
	test rax,rax
	jz .DOWN_MOVE
	cmp rax,1	; wall hit, return to loop
	je .loop	
	cmp rax,2	; hole hit, you dead
	je .FELL_IN_HOLE
	cmp rax,3
	je .DOWN_CIA
.DOWN_CIA:
	mov rdi,r14
	mov rsi,r15
	add rsi,2
	call COLLISION_CHECK
	test rax,rax
	jz .CIA_DOWN_MOVE
	cmp rax,1	; wall hit, return to loop
	je .loop
	cmp rax,2	; hole hit, he dead
	je .CIA_IN_HOLE
.CIA_DOWN_MOVE:
	inc r13
	call .DRAW_CIA_AGENT
	call print_buffer_flush
.DOWN_MOVE:
	call .CLEAR_PLAYER
	inc r15
	call .DRAW_PLAYER	
	call print_buffer_flush
	jmp .loop

.RIGHT_ARROW_PRESSED:
	mov rdi,r14
	mov rsi,r15
	inc rdi
	call COLLISION_CHECK
	test rax,rax
	jz .RIGHT_MOVE
	cmp rax,1	; wall hit, return to loop
	je .loop
	cmp rax,2	; hole hit, you dead
	je .FELL_IN_HOLE
	cmp rax,3	; cia agent hit
	je .RIGHT_CIA
.RIGHT_CIA:
	mov rdi,r14
	mov rsi,r15
	add rdi,2
	call COLLISION_CHECK
	test rax,rax
	jz .CIA_RIGHT_MOVE
	cmp rax,1	; wall hit, return to loop
	je .loop
	cmp rax,2	; hole hit, he dead
	je .CIA_IN_HOLE
.CIA_RIGHT_MOVE:
	inc r12
	call .DRAW_CIA_AGENT
	call print_buffer_flush
.RIGHT_MOVE:
	call .CLEAR_PLAYER
	inc r14
	call .DRAW_PLAYER	
	call print_buffer_flush
	jmp .loop

.LEFT_ARROW_PRESSED:
	mov rdi,r14
	mov rsi,r15
	dec rdi
	call COLLISION_CHECK
	test rax,rax
	jz .LEFT_MOVE
	cmp rax,1	; wall hit, return to loop
	je .loop	
	cmp rax,2	; hole hit, you dead
	je .FELL_IN_HOLE
	cmp rax,3	; cia agent hit
	je .LEFT_CIA
.LEFT_CIA:
	mov rdi,r14
	mov rsi,r15
	sub rdi,2
	call COLLISION_CHECK
	test rax,rax
	jz .CIA_LEFT_MOVE
	cmp rax,1	; wall hit, return to loop
	je .loop
	cmp rax,2	; hole hit, he dead
	je .CIA_IN_HOLE
.CIA_LEFT_MOVE:
	dec r12
	call .DRAW_CIA_AGENT
	call print_buffer_flush
.LEFT_MOVE:
	call .CLEAR_PLAYER
	dec r14
	call .DRAW_PLAYER	
	call print_buffer_flush
	jmp .loop

.FELL_IN_HOLE:

	cmp r9,rbx
	jle .fell_not_high_score
	mov rbx,r9

	call print_buffer_flush

	mov rdi,HIGH_SCORE_FILE
	mov rsi,SYS_READ_WRITE+SYS_TRUNCATE
	mov rdx,SYS_DEFAULT_PERMISSIONS
	call file_open
	mov rbp,rax

	mov rdi,rbp
	mov rsi,rbx
	call print_int_d

	mov rsi,PREP+1
	mov rdx,1	
	call print_chars

	call print_buffer_flush

	call file_close

.fell_not_high_score:
	; clear screen
	mov rdi,SYS_STDOUT
	mov rsi,CLEAR_SCREEN
	mov rdx,4
	call print_chars


	xor rsi,rsi
	xor rdx,rdx
	call ansi_move_cursor

	mov rsi,HOLE_GRAMMAR
	mov rdx,49
	call print_chars

	call print_buffer_flush

.DIED_LOOP:
	
	mov dword [READ_BUFFER],0

	mov rdi,SYS_STDIN
	mov rsi,READ_BUFFER
	mov rdx,4
	call read_chars

	cmp byte [READ_BUFFER+1],0
	jnz .DIED_LOOP

	cmp byte [READ_BUFFER], 27 ; ESCAPE
	je MAIN_MENU

	cmp byte [READ_BUFFER], 113 ; 'q'
	je MAIN_MENU

	cmp byte [READ_BUFFER], 114 ; 'r'
	je RESTART

	jmp .DIED_LOOP

.CIA_IN_HOLE:
	; update unalive count
	
	inc r9

	mov rdi,SYS_STDOUT
	xor rsi,rsi
	mov rdx,24
	call ansi_move_cursor

	mov rsi,CIA_UNALIVE_GRAMMAR
	mov rdx,22
	call print_chars

	mov rsi,r9
	call print_int_d

	call print_buffer_flush
	
	jmp RESTART

.CLEAR_PLAYER:
	mov rdi,SYS_STDOUT
	mov rsi,r14
	mov rdx,r15
	call ansi_move_cursor
	
	mov rsi,PLAYER+10
	mov rdx,1
	call print_chars
	ret

.DRAW_PLAYER:
	mov rdi,SYS_STDOUT
	mov rsi,r14
	mov rdx,r15
	call ansi_move_cursor
	
	mov rsi,PLAYER
	mov rdx,10
	call print_chars

;	call .UPDATE_COORDINATES

	ret		

.DRAW_CIA_AGENT:
	mov rdi,SYS_STDOUT
	mov rsi,r12
	mov rdx,r13
	call ansi_move_cursor
	
	mov rsi,CIA
	mov rdx,10
	call print_chars

	ret		

.DRAW_HOLE:
	mov rdi,SYS_STDOUT
	mov rsi,r10
	mov rdx,r11
	call ansi_move_cursor
	
	mov rsi,HOLE
	mov rdx,10
	call print_chars

	ret	
	
%if 0 ; plots coordinates of player, used for debugging
.UPDATE_COORDINATES:
	; plot (x,y) on the bottom

	xor rsi,rsi
	mov rdx,25
	call ansi_move_cursor

	mov rsi,PLOT_GRAMMAR
	mov rdx,1
	call print_chars

	mov rsi,r14
	call print_int_d

	mov rsi,PLOT_GRAMMAR+1
	mov rdx,1
	call print_chars

	mov rsi,r15
	call print_int_d

	mov rsi,PLOT_GRAMMAR+2
	mov rdx,2
	call print_chars

	ret
%endif 

COLLISION_CHECK: 	; takes ({rdi},{rsi}) as queried position on map
			; returns {rax}=0 on nothing found
			; returns {rax}=1 on wall found
			; returns {rax}=2 on hole found
			; returns {rax}=3 on cia agent found
	cmp rdi,r12
	jne .no_cia
	cmp rsi,r13
	jne .no_cia
	mov rax,3	; cia detected
	ret
	
.no_cia:
	cmp rdi,r10
	jne .no_hole
	cmp rsi,r11
	jne .no_hole
	mov rax,2	; cia detected
	ret
	
.no_hole:

	cmp rdi,40
	jge .wall_detected
	cmp rdi,1
	jle .wall_detected
	cmp rsi,20
	jge .wall_detected
	cmp rsi,1
	jle .wall_detected

	xor rax,rax
	ret

.cia_detected:
	mov rax,3
	ret

.hole_detected:
	mov rax,2
	ret

.wall_detected:
	mov rax,1
	ret

DONE:

	mov rdi,1		; flag to disable raw input mode
	call toggle_raw_mode

	; clear screen
	mov rdi,SYS_STDOUT
	mov rsi,CLEAR_SCREEN
	mov rdx,4
	call print_chars

	; turn cursor back on
	mov rsi,SHOW_CURSOR
	mov rdx,6
	call print_chars

	mov rsi,PREP
	mov rdx,2
	call print_chars

	; flush print buffer
	mov rdi,SYS_STDOUT
	call print_buffer_flush

	xor dil,dil
	call exit	

MAP_TOP_BOT:
	db `----------------------------------------\r\n`
MAP_SIDES:
	db `|                                      |\r\n`

PLOT_GRAMMAR:
	db `(,) `

HOLE_GRAMMAR:
	db `you fell in hole lol\r\nr to restart\r\nq/ESC to quit`

CIA_UNALIVE_GRAMMAR:
	db `\tcia agents unalived: `

CONTROL_GRAMMAR:
	db `    q/ESC to quit, r to remake level`

HIDE_CURSOR:
	db `\e[?25l`

SHOW_CURSOR:
	db `\e[?25h`

HIGH_SCORE_FILE:
	db `high_score.txt`,0

PLAYER:
	db `\e[32m+\e[0m `

CIA:
	db `\e[31mC\e[0m`

HOLE:
	db `\e[36mO\e[0m`

PREP:
	db `\r\n`

CLEAR_SCREEN:
	db `\e[2J`

READ_BUFFER:
	times 32 db 0

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
