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

1:
.ASCII "EXITING WITH CODE: \n"

.ENDIF

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.ALIGN 2

EXIT:	// VOID EXIT({B0});

.IFDEF VERBOSE_LOGS
        SUB SP,SP,16
        STR W0,[SP]
	_LOG_TEXT 1b 19
        LDR W0,[SP]
        AND W0,W0,0XFF
        _LOG_DECIMAL X0
        _LOG_TEXT (1b+19),1 // TODO: MAYBE REPLACE WITH LOG_CHAR OR LOG_BYTE
        LDR W0,[SP]
        ADD SP,SP,16 // UNNECESSARY
.ENDIF

	MOV W8, SYS_EXIT
	SVC 0

	RET

.ENDIF
