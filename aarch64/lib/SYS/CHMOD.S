.IFNDEF CHMOD
.EQU CHMOD,1

// TODO: TEST, i don't think this is set up correctly. i think i just copied and pasted unlink.
// needs to be tested

.INCLUDE "SYS/HELPER.S"

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.MACRO __CHMOD

	_PUSH_VOLATILES

	LDP X0,X1,[SP,VOLATILE_LENGTH+0]

	BL CHMOD

	_POP_VOLATILES

.ENDM

.MACRO _CHMOD PATH PERMISSIONS

	SUB SP,SP,16
	MOV X20,\PATH
	STR X20,[SP,0]	
	MOV X20,\PERMISSIONS
	STR X20,[SP,8]

	__CHMOD

	ADD SP,SP,16

.ENDM

.MACRO _MAKE_EXECUTABLE PATH

	_CHMOD \PATH SYS_EXECUTE_PERMISSIONS

.END

.IFDEF VERBOSE_LOGS

.INCLUDE "IO/LOG_TEXT.S"
.INCLUDE "SYS/EXIT.S"

1:	.ASCII "ATTEMPTING TO SET '"
2:	.ASCII "'. "
3:	.ASCII "FAIL.   \n"
4:	.ASCII "SUCCESS.\n"

.ENDIF

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.ALIGN 2

CHMOD:	// CHMOD({W0}, {X1});
	
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
	MOV W8, SYS_CHMOD
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
