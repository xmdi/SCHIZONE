.IFNDEF WRITE
.EQU WRITE,1

.INCLUDE "SYS/HELPER.S"

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.MACRO __WRITE

	_PUSH_VOLATILES

	LDP X0,X1,[SP,VOLATILE_LENGTH]
	LDR X2,[SP,VOLATILE_LENGTH+16]

	BL WRITE

	_POP_VOLATILES

.ENDM

.MACRO _WRITE FD BUFFER NUM_BYTES

	SUB SP,SP,32
	MOV X20,\FD
	STR X20,[SP,0]
	MOV X20,\BUFFER
	STR X20,[SP,8]
	MOV X20,\NUM_BYTES
	STR X20,[SP,16]

	__WRITE

	ADD SP,SP,32

.ENDM

.MACRO _PRINT BUFFER NUM_BYTES

	_WRITE SYS_STDOUT \BUFFER \NUM_BYTES

.ENDM

.IFDEF VERBOSE_LOGS

.INCLUDE "IO/LOG_TEXT.S"
.INCLUDE "IO/LOG_DECIMAL.S"
.INCLUDE "IO/LOG_HEXADECIMAL.S"

1:	.ASCII "ATTEMPTING TO WRITE "
2:	.ASCII "BYTES FROM 0x"
3:	.ASCII " TO FD="
4:	.ASCII ": '"
5:	.ASCII "'\n"

.ENDIF

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.ALIGN 2

WRITE:	// WRITE({W0}, {X1}, {W2});
	
.IFDEF VERBOSE_LOGS
	SUB SP,SP,48
	STP X0,X1,[SP,16]
	STP X2,X3,[SP,0]
	STR LR,[SP,32]
	_LOG_TEXT 1b 20
	LDP X2,X3,[SP,0]
	_LOG_DECIMAL X2	
	_LOG_TEXT (2b-1),14
	LDP X0,X1,[SP,16]
	_LOG_HEXADECIMAL X1
	LDP X0,X1,[SP,16]
	_LOG_TEXT 3b,7
	LDP X0,X1,[SP,16]
	_LOG_DECIMAL X0
	_LOG_TEXT 4b,3
	LDP X0,X1,[SP,16]
	LDP X2,X3,[SP,0]
	LDR LR,[SP,32]
	ADD SP,SP,32
	STP X1,X2,[SP,0]

.ENDIF

	ADD X1, X1, LOAD_ADDRESS // position independent LDR basically
	MOV W8, SYS_WRITE 
	SVC 0

.IFDEF VERBOSE_LOGS
	
	LDP X1,X2,[SP,0]
	SUB SP,SP,32
	STP X0,X1,[SP,16]
	STP X2,X3,[SP,0]
	STR LR,[SP,32]
	_LOG_TEXT X1,W2	
	_LOG_TEXT 5b,2
	LDP X0,X1,[SP,16]
	LDP X2,X3,[SP,0]
	LDR LR,[SP,32]
	ADD SP,SP,48

.ENDIF

	RET

.ENDIF
