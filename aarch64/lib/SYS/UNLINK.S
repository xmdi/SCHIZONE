.IFNDEF UNLINK
.EQU UNLINK,1

.INCLUDE "SYS/HELPER.S"

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.MACRO __UNLINK

	_PUSH_VOLATILES

	MOV X0,SYS_AT_FDCWD
	LDR X1,[SP,VOLATILE_LENGTH+0]

	BL UNLINK

	_POP_VOLATILES

.ENDM

.MACRO _UNLINK PATH

	SUB SP,SP,16
	MOV X20,\PATH
	STR X20,[SP,0]

	__UNLINK

	ADD SP,SP,16

.ENDM

.IFDEF VERBOSE_LOGS

.INCLUDE "IO/LOG_TEXT.S"

1:	.ASCII "ATTEMPTING TO UNLINK '"
2:	.ASCII "'. "
3:	.ASCII "FAIL.   \n"
4:	.ASCII "SUCCESS.\n"

.ENDIF

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.ALIGN 2

UNLINK:	// UNLINK({W0}, {X1});
	
.IFDEF VERBOSE_LOGS

	SUB SP,SP,32
	STP X0,X1,[SP,0]
	STR LR,[SP,16]
	_LOG_TEXT 1b 22
	LDP X0,X1,[SP,0]
	_LOG_NULL_TERM_STRING X1
	_LOG_TEXT 2b,3
	LDP X0,X1,[SP,0]
	LDR LR,[SP,16]
	ADD SP,SP,32

.ENDIF
	
	ADD X1,X1,LOAD_ADDRESS
	MOV W8, SYS_UNLINK
	SVC 0

.IFDEF VERBOSE_LOGS

	ADD X0,X0,1
	MOV X1,9
	MUL X0,X0,X1
	ADD X0,X0,3b
	_LOG_TEXT X0,9

.ENDIF

	RET

.ENDIF
