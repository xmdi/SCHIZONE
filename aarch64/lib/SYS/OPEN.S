.IFNDEF OPEN

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.MACRO _OPEN DIR PATH FLAGS MODE
	MOV W3, \MODE          	// mode
	MOV W2, \FLAGS       	// flags
	MOV X1, \PATH
	ADD X1, X1, LOAD_ADDRESS // position independent LDR basically
	MOV X0, \DIR	    	// dirfd = AT_FDCWD (current directory)
	BL OPEN
.ENDM

.MACRO _OPEN_RW PATH
	_OPEN SYS_AT_FDCWD \PATH SYS_READ_WRITE 0
.ENDM

.MACRO _OPEN_CREATE_EXECUTE PATH
	_OPEN SYS_AT_FDCWD \PATH (SYS_READ_WRITE|SYS_CREATE_FILE) SYS_EXECUTE_PERMISSIONS
.ENDM

.MACRO _OPEN_CREATE_DEFAULT PATH
	_OPEN SYS_AT_FDCWD \PATH (SYS_READ_WRITE|SYS_CREATE_FILE) SYS_DEFAULT_PERMISSIONS
.ENDM

.IFDEF DEBUG
// put some error message here

.MACRO _VALIDATE_OPEN
//	CMP W0,0
//	BLT

.ENDM
.ENDIF

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

OPEN:	// {W0} OPEN({W0}, {X1}, {W2}, {W3});
	// RETURNS FILE DESCRIPTOR IN {W0}

	MOV W8, SYS_OPEN 
	SVC 0
	RET

.ENDIF
