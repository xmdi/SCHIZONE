.IFNDEF READ
.EQU READ,1

.INCLUDE "SYS/HELPER.S"

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.MACRO __READ

	_PUSH_VOLATILES

	LDP X0,X1,[SP,VOLATILE_LENGTH]
	LDR X2,[SP,VOLATILE_LENGTH+16]

	BL READ

	MOV X20,X0

	_POP_VOLATILES

	MOV X0,X20

.ENDM

.MACRO _READ FD BUFFER NUM_BYTES

	SUB SP,SP,32
	MOV X20,\FD
	STR X20,[SP,0]
	MOV X20,\BUFFER
	STR X20,[SP,8]
	MOV X20,\NUM_BYTES
	STR X20,[SP,16]

	__READ

	ADD SP,SP,32

.ENDM

.IFDEF VERBOSE_LOGS

.INCLUDE "IO/LOG_TEXT.S"
.INCLUDE "IO/LOG_DECIMAL.S"

1:	.ASCII "ATTEMPTING TO READ "
2:	.ASCII "BYTES FROM FD="
3:	.ASCII ": '"
4:	.ASCII "' ("
5:	.ASCII " BYTES READ)\n"

.ENDIF

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.ALIGN 2

READ:	// {W0} READ({W0}, {X1}, {W2});
	// RETURNS NUMBER BYTES READ
	
.IFDEF VERBOSE_LOGS
	SUB SP,SP,48
	STP X0,X1,[SP,16]
	STP X2,X3,[SP,0]
	STR LR,[SP,32]
	_LOG_TEXT 1b 19
	LDP X2,X3,[SP,0]
	_LOG_DECIMAL X2	
	_LOG_TEXT (2b-1),15
	LDP X0,X1,[SP,16]
	_LOG_DECIMAL X0	
	LDP X0,X1,[SP,16]
	_LOG_TEXT 3b,3
	LDP X0,X1,[SP,16]
	LDP X2,X3,[SP,0]
	LDR LR,[SP,32]
	ADD SP,SP,32
	STR X1,[SP,0]

.ENDIF

	ADD X1, X1, LOAD_ADDRESS // position independent LDR basically
	MOV W8, SYS_READ 
	SVC 0

.IFDEF VERBOSE_LOGS
	
	LDR X1,[SP,0]
	SUB SP,SP,32
	STP X0,X1,[SP,16]
	STP X2,X3,[SP,0]
	STR LR,[SP,32]
	_LOG_TEXT X1,W0
	_LOG_TEXT 4b,3
	LDP X0,X1,[SP,16]
	_LOG_DECIMAL X0
	_LOG_TEXT 5b,13
	LDP X0,X1,[SP,16]
	LDP X2,X3,[SP,0]
	LDR LR,[SP,32]
	ADD SP,SP,48
.ENDIF

	RET

.ENDIF
