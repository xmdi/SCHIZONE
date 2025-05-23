.IFNDEF HELPER
.EQU HELPER,1

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.EQU VOLATILE_LENGTH,160

.MACRO _PUSH_VOLATILES // THIS IS BECAUSE ARM IS TRASH AND GNU IS TRASH
			// AND BOOMERS ARE TRASH
	SUB SP, SP, VOLATILE_LENGTH
	STP LR, X0, [SP,0]
	STP X1, X2, [SP,16]
	STP X3, X4, [SP,32]
	STP X5, X6, [SP,48]
	STP X7, X8, [SP,64]
	STP X9, X10, [SP,80]
	STP X11, X12, [SP,96]
	STP X13, X14, [SP,112]
	STP X15, X16, [SP,128]
	STP X17, X18, [SP,144]
.ENDM

.MACRO _POP_VOLATILES	// SAME STORY
	LDP LR, X0, [SP,0]
	LDP X1, X2, [SP,16]
	LDP X3, X4, [SP,32]
	LDP X5, X6, [SP,48]
	LDP X7, X8, [SP,64]
	LDP X9, X10, [SP,80]
	LDP X11, X12, [SP,96]
	LDP X13, X14, [SP,112]
	LDP X15, X16, [SP,128]
	LDP X17, X18, [SP,144]
	ADD SP, SP, VOLATILE_LENGTH
.ENDM

.ENDIF
