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
	.QUAD CODE_SIZE // SIZE (BYTES) OF SEGMENT IN MEMORY
	.QUAD 0X0000000000000000 // ALIGNMENT (DOESN'T MATTER, ONLY 1 SEGMENT)
END_HEADER:

//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INCLUDES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

//.EQU VERBOSE_LOGS, 1

.INCLUDE "SYS/LINUX/SYSCALLS.S"
.INCLUDE "IO/LOG_FILE.S"
.INCLUDE "SYS/OPEN.S"
.INCLUDE "SYS/READ.S"
.INCLUDE "SYS/WRITE.S"
.INCLUDE "SYS/EXIT.S"

//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:

//	_LOG_FILE .LOGFILENAME // UNCOMMENT TO SEND VERBOSE LOGS TO FILE
	
	_OPEN_RW .FILENAME
	
//	SUB SP,SP,16
//	STR X0,[SP,0]
	
	_READ X0, .BUFFER, 32
	
	_PRINT .BUFFER, 32

	_EXIT 0

.BUFFER:
	.SPACE 32

.LOGFILENAME:
	.ASCII "log.file\0"

.FILENAME:
	.ASCII "test.file\0"

END:
