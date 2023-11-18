; syscall ID numbers; put these in {rax}
%define SYS_EXIT 1
%define SYS_READ 3
%define SYS_WRITE 4
%define SYS_OPEN 5
%define SYS_CLOSE 6
%define SYS_UNLINK 10
%define SYS_CHMOD 15
%define SYS_IOCTL 54
%define SYS_GETTIMEOFDAY 116
%define SYS_LSEEK 478
%define SYS_GETRANDOM 563

; file descriptors
%define SYS_STDIN 0
%define SYS_STDOUT 1
%define SYS_STDERR 2

; permissions for SYS_OPEN
%define SYS_READ_ONLY 0x000
%define SYS_WRITE_ONLY 0x001
%define SYS_READ_WRITE 0x002
%define SYS_CREATE_FILE 0x200
%define SYS_TRUNCATE 0x400
%define SYS_DEFAULT_PERMISSIONS 644o
%define SYS_EXECUTE_PERMISSIONS 755o

; ioctl
%define SYS_TCGETA 0x402c7413 ; actually TIOCGETA
%define SYS_TCSETA 0x802c7414 ; actually TIOCSETA

; termios input flags
%define SYS_IGNBRK 0x1 ; ignore BREAK condition
%define SYS_BRKINT 0x2 ; map BREAK to SIGINTR
%define SYS_IGNPAR 0x4 ; ignore parity errors
%define SYS_PARMRK 0x8 ; mark parity and framing errors
%define SYS_INPCK 0x10 ; enable checking of parity errors
%define SYS_ISTRIP 0x20 ; strip 8th bit off chars
%define SYS_INLCR 0x40 ; map newline to carriage return
%define SYS_IGNCR 0x80 ; ignore carriage return
%define SYS_ICRNL 0x100 ; map carriage return to newline
%define SYS_IXON 0x200 ; enable output flow control
%define SYS_IXOFF 0x400 ; enable input flow control

; termios output flags
%define SYS_OPOST 0x1 ; enable ouput processing

; termios control flags
%define SYS_CSIZE 0x300 ; character size mask
%define SYS_CS5 0x0	; 5 bits (pseudo)
%define SYS_CS6 0x100	; 6 bits
%define SYS_CS7 0x200	; 7 bits
%define SYS_CS8 0x300	; 8 bits
%define SYS_PARENB 0x1000 ; parity enable

; termios local flags
%define SYS_ECHO 0x8 ; enable echoing
%define SYS_ECHONL 0x10 ; echo newline even if ECHO is off
%define SYS_ICANON 0x100 ; canonicalize input lines
%define SYS_ISIG 0x80 ; enable INTR, QUIT, (D)SUSP signals
%define SYS_IEXTEN 0x400 ; enable DISCARD and LNEXT

; lseek modes
%define SYS_SEEK_SET 0 ; seek offset relative to file start
%define SYS_SEEK_CUR 1 ; seek offset relative to current position
%define SYS_SEEK_END 2 ; seek offset relative to file end

; pointer to argc at program start
%define SYS_ARGC_START_POINTER rdi

%macro SYS_PUSH_SYSCALL_CLOBBERED_REGISTERS 0
	push rcx
	push r8
	push r9
	push r10
	push r11
%endmacro

%macro SYS_POP_SYSCALL_CLOBBERED_REGISTERS 0
	pop r11
	pop r10
	pop r9
	pop r8
	pop rcx
%endmacro
