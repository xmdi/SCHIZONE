.IFNDEF SLEEP
.EQU SLEEP,1

.IFDEF VERBOSE_LOGS
	.INCLUDE "IO/LOG_FILE.S"
	.INCLUDE "IO/LOG_TEXT.S"
	.INCLUDE "IO/LOG_DECIMAL.S"
.ENDIF

.INCLUDE "SYS/OPEN.S"
.INCLUDE "SYS/EXIT.S"

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.MACRO _MICROSLEEP NUMBER
	SUB SP,SP,32
	STP LR,X0,[SP,0]
	STP X1,X8,[SP,16]
	MOV X0,\NUMBER
	BL MICROSLEEP
	LDP LR,X0,[SP,0]
	LDP X1,X8,[SP,16]
	ADD SP,SP,32
.ENDM

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.ALIGN 2
MICROSLEEP:

.IFDEF VERBOSE_LOGS
	_LOG_NULL_TERM_STRING SLEEP_START_STRING
	_LOG_DECIMAL X0
	_LOG_NULL_TERM_STRING SLEEP_MICROSECOND_STRING
.ENDIF
	
	SUB SP, SP, 16
	MOV X1, 1000
	MUL X1, X0, X1 // us -> ns
	STP XZR, X1, [SP] // nanosleep reads from an address
	MOV X0, SP
	MOV X1, 0
	MOV X8, SYS_NANOSLEEP
	SVC 0
	ADD SP, SP, 16

.IFDEF VERBOSE_LOGS
	_LOG_NULL_TERM_STRING SLEEP_COMPLETE_STRING
.ENDIF

	RET

.IFDEF VERBOSE_LOGS
SLEEP_START_STRING:
	.ASCIZ "SLEEPING FOR \0"
SLEEP_MICROSECOND_STRING:
	.ASCIZ " MICROSECONDS \0"
SLEEP_COMPLETE_STRING:
	.ASCIZ "...AND AWOKE!\n\0"
.ENDIF

.ENDIF
