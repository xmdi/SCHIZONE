//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.ARCH armv8-a
.EQU LOAD_ADDRESS, 0X8000
.EQU CODE_SIZE, (END-END_HEADER) // EVERYTHING BEYOND THE HEADER IS CODE

//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;HEADER;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ELF_HEADER:
	.BYTE 0X7F,'E','L','F' // MAGIC NUMBER TO INDICATE ELF FILE
	.BYTE 0X02 // 0X1 FOR 32-BIT, 0X2 FOR 64-BIT
	.BYTE 0X01 // 0X1 FOR LITTLE ENDIAN, 0X2 FOR BIG ENDIAN
	.BYTE 0X01 // 0X1 FOR CURRENT VERSION OF ELF
	.BYTE 0X00 // 0X9 FOR FREEBSD, 0X3 FOR LINUX (DOESN'T SEEM TO MATTER)
	.BYTE 0X00 // ABI VERSION (IGNORED?)
	.FILL 7, 1, 0X00 // 7 PADDING BYTES
	.SHORT 0X0002 // EXECUTABLE FILE
	.SHORT 0X00B7 // ARMV8A
	.WORD 0X00000001 // VERSION 1
	.QUAD LOAD_ADDRESS+(START-ELF_HEADER) // ENTRY POINT FOR OUR PROGRAM
	.QUAD 0X0000000000000040 // 0X40 OFFSET FROM TO PROGRAM_HEADER
	.QUAD 0X0000000000000000 // SECTION HEADER OFFSET (WE DON'T HAVE THIS)
	.WORD 0X00000000 // UNUSED FLAGS
	.SHORT 0X0040 // 64-BYTE SIZE OF ELF_HEADER
	.SHORT 0X0038 // 56-BYTE SIZE OF EACH PROGRAM HEADER ENTRY
	.SHORT 0X0001 // NUMBER OF PROGRAM HEADER ENTRIES (WE HAVE ONE)
	.SHORT 0X0000 // SIZE OF EACH SECTION HEADER ENTRY (NONE)
	.SHORT 0X0000 // NUMBER OF SECTION HEADER ENTRIES (NONE)
	.SHORT 0X0000 // INDEX IN SECTION HEADER TABLE FOR SECTION NAMES (WASTE)
PROGRAM_HEADER:
	.WORD 0X00000001 // 0X1 FOR LOADABLE PROGRAM SEGMENT
	.WORD 0X00000007 // READ/WRITE/EXECUTE FLAGS
	.QUAD 0X0000000000000078 // OFFSET OF CODE START IN FILE IMAGE
	.QUAD LOAD_ADDRESS+0X78 // VIRTUAL ADDRESS OF SEGMENT IN MEMORY
	.QUAD 0X0000000000000000 // PHYSICAL ADDRESS OF SEGMENT IN MEMORY
	.QUAD CODE_SIZE // SIZE (BYTES) OF SEGMENT IN FILE IMAGE
	.QUAD CODE_SIZE+BUFFER_SIZE // SIZE (BYTES) OF SEGMENT IN MEMORY
	.QUAD 0X0000000000000000 // ALIGNMENT (DOESN'T MATTER, ONLY 1 SEGMENT)
END_HEADER:

//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INCLUDES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.INCLUDE "SYS/LINUX/SYSCALLS.S"

//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:

	// CHECK IF NUMBER OF PARAMETERS CORRECT
	LDR X1,[SP,0]
	CMP X1,3
	B.EQ FILE_GIVEN
	
	MOV W0,1
	MOV W8,SYS_EXIT
	SVC 0

FILE_GIVEN:

	SUB SP,SP,16

	// GRAB FIRST ARGUMENT FOR BOOMER OBJECT FILE
	LDR X1,[SP,32]
	SUB X1,X1,LOAD_ADDRESS // CONVERT TO CHALK ZONE MEMORY COORDINATES
	MOV X0,SYS_AT_FDCWD
	MOV X2,SYS_READ_WRITE
	MOV X3,0
	MOV W8,SYS_OPEN
	SVC 0	

	STR X0,[SP,0]	// BOOMER FD AT [SP+0]
	
	// GRAB SECOND ARGUMENT FOR OUTPUT BINARY
	LDR X1,[SP,40]
	SUB X1,X1,LOAD_ADDRESS // CONVERT TO CHALK ZONE MEMORY COORDINATES
	MOV X0,SYS_AT_FDCWD
	MOV X2,(SYS_READ_WRITE+SYS_CREATE_FILE+SYS_TRUNCATE)
	MOV X3,SYS_EXECUTE_PERMISSIONS
	MOV W8,SYS_OPEN
	SVC 0

	STR X0,[SP,8]	// BINARY FD AT [SP+8]

	LDR X0,[SP,0]
	// GET FILESIZE OF BINARY IMAGE
	MOV X1,160
	MOV X2, SYS_SEEK_SET // LSEEK TO BYTE 160 FROM FILE START
	MOV W8,SYS_LSEEK
	SVC 0

	LDR X0,[SP,0]
	MOV X1,.IMAGE_SIZE
	MOV X2,8 // READ 8 BYTES
	MOV W8,SYS_READ	
	SVC 0
	
	MOV X0,.IMAGE_SIZE
	ADD X0,X0,LOAD_ADDRESS
	LDR X0,[X0]
	// (?) CONVERT TO SENSIBLE ENDIANNESS TODO MAYBE FOR LARGER FILESIZE
	LDR X0,[SP,0]
	MOV X1,64
	MOV X2,SYS_SEEK_SET
	MOV W8,SYS_LSEEK
	SVC 0
	// LSEEK TO BYTE 64 FROM FILE START (START OF EMBEDDED BINARY)

	MOV X0,.IMAGE_SIZE
	ADD X0,X0,LOAD_ADDRESS
	LDR X19,[X0]
	ADD X19,X19,120
	// X19 WILL TRACK NUMBER OF BYTES LEFT TO WRITE/READ

.LOOP:
	SUBS X20,X19,BUFFER_SIZE
	// IF X20 IS NEGATIVE, GO TO FINAL READ/WRITE OP
	// OTHERWISE READ/WRITE THE BUFFER SIZE AND CONTINUE
	B.GT .CONTINUE	

	// READ DATA FROM BOOMER FILE
	LDR X0,[SP,0]
	MOV X1,.BUFFER
	MOV X2,X19
	MOV W8,SYS_READ
	SVC 0

	// COPY DATA INTO OUTPUT BINARY
	LDR X0,[SP,8]
	MOV X1,.BUFFER
	MOV X2,X19
	MOV W8,SYS_WRITE
	SVC 0

.DONE:

	ADD SP,SP,16 // NOT REQ?
	// DELETE BOOMER FILE
	LDR X1,[SP,16]	
	SUB X1,X1,LOAD_ADDRESS
	MOV X0,SYS_AT_FDCWD
	MOV W8,SYS_UNLINK
	SVC 0	
	
	MOV W8,SYS_EXIT
	SVC 0

.CONTINUE:

	// READ DATA FROM BOOMER FILE
	LDR X0,[SP,0]
	MOV X1,.BUFFER
	MOV X2,BUFFER_SIZE
	MOV W8,SYS_READ
	SVC 0

	// COPY DATA INTO OUTPUT BINARY
	LDR X0,[SP,8]
	MOV X1,.BUFFER
	MOV X2,BUFFER_SIZE
	MOV W8,SYS_WRITE
	SVC 0

	SUB X19,X19,BUFFER_SIZE

	B .LOOP

.IMAGE_SIZE:
	.SPACE 8

.EQU BUFFER_SIZE,1024
.BUFFER:

END:
