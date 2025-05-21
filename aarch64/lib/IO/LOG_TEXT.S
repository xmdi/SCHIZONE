.IFNDEF LOG_TEXT
.EQU LOG_TEXT,1

.INCLUDE "IO/LOG_FILE.S"
.INCLUDE "IO/STRLEN.S"

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.MACRO _PRINT_TEXT FILE_DESCRIPTOR TEXT NUM_BYTES
	SUB SP, SP, 32
	STP X1, LR, [SP,16]
	STR X2, [SP,0]
	
	MOV W2, \NUM_BYTES
	MOV X1, \TEXT 
	LDR W0, \FILE_DESCRIPTOR
	BL LOG_TEXT

	LDP X1, LR, [SP,16]
	LDR X2, [SP,0]
	ADD SP, SP, 32
.ENDM

.MACRO _PRINT_NULL_TERM_STRING FILE_DESCRIPTOR TEXT

	SUB SP, SP, 32
	STP X0, LR, [SP,16]
	STP X1, X2, [SP,0]

	_STRLEN \TEXT

	MOV W2, W0
	LDR W0, \FILE_DESCRIPTOR
	MOV X1, \TEXT
	BL LOG_TEXT

	LDP X0, LR, [SP,16]
	LDP X1, X2, [SP,0]
	ADD SP, SP, 32

.ENDM

.MACRO _LOG_TEXT TEXT NUM_BYTES

	_PRINT_TEXT LOG_FILE_DESCRIPTOR /TEXT /NUM_BYTES

.ENDM

.MACRO _LOG_NULL_TERM_STRING TEXT

	_PRINT_NULL_TERM_STRING LOG_FILE_DESCRIPTOR /TEXT

.ENDM

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

LOG_TEXT:// {W0} LOG_TEXT({W0}, {X1}, {W2});
	// RETURNS NUMBER BYTES WRITTEN IN {W0}

	ADD X1, X1, LOAD_ADDRESS 
	MOV W8, SYS_WRITE
	SVC 0
	RET

.ENDIF
