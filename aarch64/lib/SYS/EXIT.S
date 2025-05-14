.IFNDEF EXIT

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.MACRO _EXIT NUMBER // NUMBER OR REGISTER
	MOV W0, \NUMBER
        BL EXIT
.ENDM

.IFDEF VERBOSE_LOGS

.INCLUDE "IO/LOG_TEXT.S"
.INCLUDE "IO/LOG_DECIMAL.S"

EXIT_VERBOSE:

.T1:
	.ASCII "EXITING WITH CODE: "

.ENDIF

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.ALIGN 2

EXIT:	// VOID EXIT({B0});

.IFDEF VERBOSE_LOGS
        SUB SP,SP,4
        STR W0,[SP]
	_LOG_TEXT EXIT_VERBOSE.T1 19
        LDR W0,[SP]
        AND W0,W0,0XFF
        _LOG_DECIMAL X0
        _LOG_BYTE "\n"
        LDR W0,[SP]
        ADD SP,SP,4 // UNNECESSARY
.ENDIF

	MOV W8, SYS_EXIT
	SVC 0

	RET

.ENDIF
