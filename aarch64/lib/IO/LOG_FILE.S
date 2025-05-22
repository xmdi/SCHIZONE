.IFNDEF LOG_FILE
.EQU LOG_FILE,1

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.MACRO _LOG_FILE PATH

.IFDEF VERBOSE_LOGS

	SUB SP,SP,48
	STP X0,X1,[SP,32]
	STP X2,X3,[SP,16]
	STR X8,[SP,0]

	MOV W3, SYS_DEFAULT_PERMISSIONS          	// mode
	MOV W2, (SYS_READ_WRITE+SYS_CREATE_FILE+SYS_TRUNCATE) 	// flags
	MOV X1, \PATH
	ADD X1, X1, LOAD_ADDRESS // position independent LDR basically
	MOV X0, SYS_AT_FDCWD	    	// dirfd = AT_FDCWD (current directory)
	MOV W8, SYS_OPEN 
	SVC 0

	MOV X1,LOG_FILE_DESCRIPTOR
	ADD X1,X1,LOAD_ADDRESS
	STR W0,[X1]

	LDP X0,X1,[SP,32]
	LDP X2,X3,[SP,16]
	LDR X8,[SP,0]
	ADD SP,SP,48

.ENDIF

.ENDM

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

LOG_FILE_DESCRIPTOR:
	.WORD SYS_STDOUT

.ENDIF
