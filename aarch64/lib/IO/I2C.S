.IFNDEF I2C
.EQU I2C,1

.IFDEF VERBOSE_LOGS
	.INCLUDE "IO/LOG_FILE.S"
	.INCLUDE "IO/LOG_TEXT.S"
.ENDIF

.INCLUDE "SYS/OPEN.S"
.INCLUDE "SYS/EXIT.S"

I2C_DEVICE:
	.ASCIZ "/dev/i2c-1"

.ALIGN 2
I2C_FD:
	.WORD 0

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.MACRO _I2C_OPEN
	SUB SP,SP,80
	STP LR,X0,[SP,0]
	STP X1,X2,[SP,16]
	STP X3,X8,[SP,32]
	BL I2C_OPEN
	LDP LR,X0,[SP,0]
	LDP X1,X2,[SP,16]
	LDP X3,X8,[SP,32]
	ADD SP,SP,48
.ENDM

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.ALIGN 2
I2C_OPEN:
//	fd = openat(AT_FDCWD, "/dev/i2c-1", O_RDWR, 0)
	MOV X0, SYS_AT_FDCWD
	ADR X1, I2C_DEVICE
	MOV X2, SYS_READ_WRITE
	MOV X3, 0
	MOV X8, SYS_OPEN
	SVC 0
	CMP X0, 0
	B.LT 1f
	ADR X1, I2C_FD
	STR W0, [X1]
.IFDEF VERBOSE_LOGS
	_LOG_NULL_TERM_STRING I2C_SUCCESS_OPEN
.ENDIF
	RET

1: 
.IFDEF VERBOSE_LOGS
	_LOG_NULL_TERM_STRING I2C_ERROR_OPEN
.ENDIF
	_EXIT 1

.IFDEF VERBOSE_LOGS
I2C_ERROR_OPEN:
	.ASCIZ "ERROR OPENING I2C FILE: /dev/i2c-1\n\0"
I2C_SUCCESS_OPEN:
	.ASCIZ "OPENED I2C FILE: /dev/i2c-1\n\0"

.ENDIF

.ENDIF
