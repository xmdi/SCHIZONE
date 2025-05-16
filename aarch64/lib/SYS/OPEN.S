.IFNDEF OPEN
.EQU OPEN,1

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.MACRO _OPEN DIR PATH FLAGS MODE
	SUB SP, SP, 32
	STP LR, X1, [SP,16]
	STP X2, X3, [SP,0]
	MOV W3, \MODE          	// mode
	MOV W2, \FLAGS       	// flags
	MOV X1, \PATH
	MOV X0, \DIR	    	// dirfd = AT_FDCWD (current directory)
	BL OPEN	
	LDP LR, X1, [SP,16]
	LDP X2, X3, [SP,0]
	ADD SP, SP, 32
.ENDM

.MACRO _OPEN_RW PATH
	_OPEN SYS_AT_FDCWD \PATH SYS_READ_WRITE 0
.ENDM

.MACRO _OPEN_CREATE_EXECUTE PATH
	_OPEN SYS_AT_FDCWD,\PATH,(SYS_READ_WRITE+SYS_CREATE_FILE),SYS_EXECUTE_PERMISSIONS
.ENDM

.MACRO _OPEN_CREATE_DEFAULT PATH
	_OPEN SYS_AT_FDCWD,\PATH,(SYS_READ_WRITE+SYS_CREATE_FILE),SYS_DEFAULT_PERMISSIONS
.ENDM

.IFDEF VERBOSE_LOGS

.INCLUDE "IO/LOG_TEXT.S"
.INCLUDE "IO/LOG_DECIMAL.S"

1:
	.ASCII "OPENING: '"
2:
	.ASCII "' SUCCESS. FD="
3:
	.ASCII "' FAIL.\n"

.ENDIF

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.ALIGN 2

OPEN:	// {W0} OPEN({W0}, {X1}, {W2}, {W3});
	// RETURNS FILE DESCRIPTOR IN {W0}

.IFDEF VERBOSE_LOGS
	SUB SP,SP,48
	STP X0,X1,[SP,16]
	STP X2,X3,[SP,0]
	STR LR,[SP,32]
	_LOG_TEXT 1b 10
	LDP X0,X1,[SP,16]
	_LOG_NULL_TERM_STRING X1 // LOG FILENAME
	LDP X0,X1,[SP,16]
	LDP X2,X3,[SP,0]
	LDR LR,[SP,32]
	ADD SP,SP,48
.ENDIF
	
	ADD X1, X1, LOAD_ADDRESS // position independent LDR basically
	MOV W8, SYS_OPEN 
	SVC 0

.IFDEF VERBOSE_LOGS
        SUB SP,SP,16
        STR W0,[SP]
	CMP W0,0
	B.GE .SUCCESS
.FAIL:
	_LOG_TEXT 3b 8
	B .QUIT
.SUCCESS:
	_LOG_TEXT 2b 14
        LDR W0,[SP]
  	_LOG_DECIMAL X0
        _LOG_TEXT (3b+7),1
.QUIT:
	LDR W0,[SP]
        ADD SP,SP,16
.ENDIF

	RET

.ENDIF
