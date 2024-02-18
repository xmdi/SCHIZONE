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

%include "lib/mem/heap_init.asm"
; void heap_init(void);

%include "lib/mem/heap_alloc.asm"
; void* {rax} heap_alloc(long {rdi});

%include "lib/math/expressions/trig/sine.asm"
; double {xmm0} sine(double {xmm0}, double {xmm1});

%include "lib/math/expressions/trig/cosine.asm"
; double {xmm0} cosine(double {xmm0}, double {xmm1});

%include "lib/sys/exit.asm"
; void exit(char {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GENERATE_LADDER_SYSTEM:
	; returns a pointer to 3D frame FEA structure in {rax} for a ladder with
	;	a 200-lb person standing on the top rung (top rung will always
	;	have an even number of elements >= {rsi}).

	; {rdi} = # rungs
	; {rsi} = # elements/rung
	; {rdx} = # side rail elements between rungs
	; {rcx} = (double) length of rungs
	; {r8}  = (double) length of each side rails
	; {r9}  = (double) rung diameter
	; {r10} = (double) side rail cross-sectional width
	; {r11} = (double) side rail cross-sectional height
	; {r12} = {double} elastic modulus E
	; {r13} = {double} shear modulus G
	; {r14} = {double} ladder angle (degrees)

	; 3D frame FEA system has this form:
	%if 0
	.3D_FRAME:
		dq 0 ; number of nodes (6 DOF per node)
		dq 0 ; number of elements
		dq 0 ; pointer to node coordinate array
			; each row: (double) x,y,z
		dq 0 ; pointer to element array 
			; each row: (long) nodeID_A,nodeID_B,elementType
		dq 0 ; pointer to stiffness matrix (K)
		dq 0 ; pointer to known forcing array (F)
	%endif

	; initialize heap if not already
	call heap_init

	; allocate space for 3D frame system
	push rdi
	mov rdi,48
	call heap_alloc ; 3D frame system at {rax}
	pop rdi

	; compute number of nodes
	mov r15,rdi
	push rsi
	inc rsi
	imul r15,rsi
	test rsi,1
	jz .even_rung_elements
	inc r15
.even_rung_elements:
	push rdi
	push rdx
	inc rdi
	dec rdx
	imul rdi,rdx
	shl rdi,1
	add r15,rdi
	pop rdx
	pop rdi	
	pop rsi
	mov [rax+0],r15

	; compute number of elements
	push rdi
	push rdx
	inc rdi
	shl rdx,1
	add rdx,rsi
	imul rdi,rdx
	sub rdi,rsi
	mov [rax+8],rdi
	pop rdx

	; allocate space for node array
	mov r15,rax
	mov rdi,[rax+0]
	imul rdi,rdi,24
	call heap_alloc
	mov [r15+16],rax

	; allocate space for element array
	mov rdi,[rax+8]
	imul rdi,rdi,24
	call heap_alloc
	mov [r15+24],rax
	
	; allocate space for stiffness matrix (K)
	mov rdi,[rax+0]
	imul rdi,rdi
	imul rdi,rdi,288
	call heap_alloc
	mov [r15+32],rax

	; allocate space for known forcing matrix (F)
	mov rdi,[rax+0]
	imul rdi,rdi,48
	call heap_alloc
	mov [r15+40],rax
	mov rax,r15
	pop rdi

	; populate the node coordinate array


	; populate the element array




	ret

.convert_deg_to_radians:
	dq 0.01745329251

START:
	; generate ladder system (nodes and elements)
	mov rdi,

	; exit
	xor dil,dil
	call exit

.number_rungs:
	dq 8
.number_elements_per_rung:
	dq 2
.number_side_rail_elements_between_rungs:
	dq 2
.rung_length:
	dq 2.0
.side_rail_length:
	dq 10.0
.rung_diameter:
	dq 1.0
.side_rail_cross-sectional_width:
	dq 1.0
.side_rail_cross-sectional_height:
	dq 2.0
.E:
	dq 1000000.0
.G:
	dq 1000000.0

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)

