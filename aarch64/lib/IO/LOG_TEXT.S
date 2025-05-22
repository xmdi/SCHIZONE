.IFNDEF LOG_TEXT
.EQU LOG_TEXT,1

.INCLUDE "IO/LOG_FILE.S"
.INCLUDE "IO/STRLEN.S"

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.MACRO _LOG_TEXT TEXT NUM_BYTES
	SUB SP, SP, 32
	STP X1, LR, [SP,16]
	STR X2, [SP,0]
	
	MOV W2, \NUM_BYTES
	MOV X1, \TEXT 
	BL LOG_TEXT

	LDP X1, LR, [SP,16]
	LDR X2, [SP,0]
	ADD SP, SP, 32
.ENDM

.MACRO _LOG_NULL_TERM_STRING TEXT

	SUB SP, SP, 32
	STP X0, LR, [SP,16]
	STP X1, X2, [SP,0]

	_STRLEN \TEXT

	MOV W2, W0
	MOV X1, \TEXT
	BL LOG_TEXT

	LDP X0, LR, [SP,16]
	LDP X1, X2, [SP,0]
	ADD SP, SP, 32

.ENDM

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

LOG_TEXT:// {W0} LOG_TEXT({X1}, {W2});
	// RETURNS NUMBER BYTES WRITTEN IN {W0}

	LDR W0, LOG_FILE_DESCRIPTOR
	ADD X1, X1, LOAD_ADDRESS 
	MOV W8, SYS_WRITE
	SVC 0
	RET

.ENDIF
