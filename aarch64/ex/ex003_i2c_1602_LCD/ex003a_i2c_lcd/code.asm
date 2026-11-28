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

.EQU VERBOSE_LOGS, 1

.INCLUDE "SYS/LINUX/SYSCALLS.S"
.INCLUDE "IO/LOG_FILE.S"
.INCLUDE "IO/I2C.S"
.INCLUDE "IO/LCD_1602.S"
.INCLUDE "SYS/SLEEP.S"
.INCLUDE "SYS/EXIT.S"

//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:

	_LOG_FILE .LOGFILENAME // UNCOMMENT TO SEND VERBOSE LOGS TO FILE

	_I2C_OPEN

	_I2C_SELECT_DEVICE LCD_1602_ADDR

	_LCD_1602_INIT

	_LCD_1602_CUSTOM_CHAR 0 CROSS

	_LCD_1602_SET_CURSOR 0 0

	_LCD_1602_PRINT MSG1

	_LCD_1602_SET_CURSOR 1 0

	_LCD_1602_PRINT MSG2
	
	_EXIT 0

MSG1:   .asciz "jeffrey epstein"

MSG2:   .asciz "shot JFK \010" // 8 in octal gives 0 and avoid the null-terminator issue, or you can just use slots 1-7 and skip 0

CROSS:
	.BYTE 0b00000100
	.BYTE 0b00000100
	.BYTE 0b00011111
	.BYTE 0b00000100
	.BYTE 0b00000100
	.BYTE 0b00000100
	.BYTE 0b00000100
	.BYTE 0b00000100

.LOGFILENAME:
	.ASCII "log.file\0"

END:
