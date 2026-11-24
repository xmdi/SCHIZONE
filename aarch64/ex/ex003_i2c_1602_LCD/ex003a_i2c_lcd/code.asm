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
.INCLUDE "SYS/OPEN.S"
.INCLUDE "SYS/READ.S"
.INCLUDE "SYS/EXIT.S"

//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

msg1:   .asciz "Oi, Pi Zero!"
msg2:   .asciz "AArch64 asm"

.align 4
delay_us:
    stp  x29, x30, [sp, -32]!
    mov  x1, 1000
    mul  x1, x0, x1            //@ us -> ns
    str  xzr, [sp, 16]         //@ tv_sec  = 0
    str  x1,  [sp, 24]         //@ tv_nsec
    add  x0, sp, 16
    mov  x1, 0
    mov  x8, SYS_NANOSLEEP
    svc  0
    ldp  x29, x30, [sp], 32
    ret

//@ i2c_write_byte: w0 = byte for the PCF8574
i2c_write_byte:
    stp  x29, x30, [sp, -32]!
    strb w0, [sp, 16]
    adr x1, I2C_FD
    ldr w0, [x1]
    add  x1, sp, 16
    mov  x2, 1
    mov  x8, SYS_WRITE
    svc  0
    ldp  x29, x30, [sp], 32
    ret

//@ lcd_pulse: w0 = nibble|flags; latch with EN high then low
lcd_pulse:
    stp  x29, x30, [sp, -32]!
    str  x19, [sp, 16]
    mov  w19, w0
    orr  w0, w19, LCD_1602_EN
    bl   i2c_write_byte
    mov  x0, 1
    bl   delay_us
    mov  w1, LCD_1602_EN
    bic  w0, w19, w1
    bl   i2c_write_byte
    mov  x0, 50
    bl   delay_us
    ldr  x19, [sp, 16]
    ldp  x29, x30, [sp], 32
    ret

//@ lcd_send: w0 = byte, w1 = mode (0 = command, RS = data)
lcd_send:
    stp  x29, x30, [sp, -32]!
    stp  x19, x20, [sp, 16]
    mov  w19, w0
    mov  w20, w1
    and  w0, w19, 0xF0        // @ high nibble
    orr  w0, w0, w20
    orr  w0, w0, LCD_1602_BL
    bl   lcd_pulse
    lsl  w0, w19, 4           //@ low nibble
    and  w0, w0, 0xF0
    orr  w0, w0, w20
    orr  w0, w0, LCD_1602_BL
    bl   lcd_pulse
    ldp  x19, x20, [sp, 16]
    ldp  x29, x30, [sp], 32
    ret

lcd_cmd:
    mov  w1, 0
    b    lcd_send

lcd_char:
    mov  w1, LCD_1602_RS
    b    lcd_send

//@ lcd_print: x0 = pointer to null-terminated string
lcd_print:
    stp  x29, x30, [sp, -32]!
    str  x19, [sp, 16]
    mov  x19, x0
1:  ldrb w0, [x19], 1
    cbz  w0, 2f
    bl   lcd_char
    b    1b
2:  ldr  x19, [sp, 16]
    ldp  x29, x30, [sp], 32
    ret

//@ lcd_init: HD44780 4-bit init sequence
lcd_init:
    stp  x29, x30, [sp, -16]!
    mov  x0, 50000          //   @ >40ms after power-up
    bl   delay_us

    mov  w0, (0x30 | LCD_1602_BL)
    bl   lcd_pulse
    mov  x0, 4500
    bl   delay_us
    mov  w0, (0x30 | LCD_1602_BL)
    bl   lcd_pulse
    mov  x0, 200
    bl   delay_us
    mov  w0, (0x30 | LCD_1602_BL)
    bl   lcd_pulse
    mov  x0, 200
    bl   delay_us

    mov  w0, (0x20 | LCD_1602_BL)       //@ switch to 4-bit mode
    bl   lcd_pulse
    mov  x0, 200
    bl   delay_us

    mov  w0, 0x28              //@ 4-bit, 2 lines, 5x8 font
    bl   lcd_cmd
    mov  w0, 0x0C              //@ display on, cursor off
    bl   lcd_cmd
    mov  w0, 0x0             // @ clear
    bl   lcd_cmd
    mov  x0, 2000
    bl   delay_us
    mov  w0, 0x06            //  @ entry mode: increment
    bl   lcd_cmd
    ldp  x29, x30, [sp], 16
    ret

START:

	_LOG_FILE .LOGFILENAME // UNCOMMENT TO SEND VERBOSE LOGS TO FILE

	_I2C_OPEN

    //@ ioctl(fd, I2C_SLAVE, LCD_ADDR)   (x0 still holds fd)
	//MOV X0, I2C_FD
	ADR X1, I2C_FD
	LDR W0, [X1]
	MOV X1, SYS_I2C_SLAVE
	MOV X2, LCD_1602_ADDR
	MOV X8, SYS_IOCTL
	SVC 0
	CMP X0, 0
	B.LT FAIL

    bl   lcd_init

    mov  w0, 0x80           //   @ line 1, col 0
    bl   lcd_cmd
    adr x0, msg1
    bl lcd_print

    mov  w0, 0xC0        //      @ line 2, col 0
    bl   lcd_cmd
    adr x0, msg2
    bl lcd_print

	_EXIT 0

FAIL:
	_EXIT 7

.LOGFILENAME:
	.ASCII "log.file\0"

END:
