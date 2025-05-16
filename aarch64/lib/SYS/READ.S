.IFNDEF READ
.EQU READ,1

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.MACRO _READ FD BUFFER NUM_BYTES

	SUB SP,SP,32
	STP LR,X0,[SP,16]
	STP X1,X2,[SP,0]

	MOV W0,\FD
	MOV X1,\BUFFER
	MOV W2,\NUM_BYTES
	BL READ

	LDP LR,X0,[SP,16]
	LDP X1,X2,[SP,0]
	ADD SP,SP,32

.ENDM

.IFDEF VERBOSE_LOGS

.INCLUDE "IO/LOG_TEXT.S"
.INCLUDE "IO/LOG_DECIMAL.S"

1:
	.ASCII "READING: '"

.ENDIF

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.ALIGN 2

READ:	// {W0} READ({W0}, {X1}, {W2});
	// RETURNS NUMBER BYTES READ
	
	ADD X1, X1, LOAD_ADDRESS // position independent LDR basically
	MOV W8, SYS_READ 
	SVC 0

	RET

.ENDIF
