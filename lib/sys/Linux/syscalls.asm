; syscall ID numbers; put these in {rax}
%define SYS_READ 0
%define SYS_WRITE 1
%define SYS_OPEN 2
%define SYS_CLOSE 3
%define SYS_LSEEK 8
%define SYS_IOCTL 16
%define SYS_EXIT 60
%define SYS_UNLINK 87
%define SYS_CHMOD 90
%define SYS_GETTIMEOFDAY 96
%define SYS_GETRANDOM 318

; file descriptors
%define SYS_STDIN 0
%define SYS_STDOUT 1
%define SYS_STDERR 2

; permissions for SYS_OPEN
%define SYS_READ_ONLY 0x000
%define SYS_WRITE_ONLY 0x001
%define SYS_READ_WRITE 0x002
%define SYS_CREATE_FILE 0x040
%define SYS_TRUNCATE 0x200
%define SYS_DEFAULT_PERMISSIONS 644o
%define SYS_EXECUTE_PERMISSIONS 755o

; ioctl
%define SYS_TCGETA 0x5401
%define SYS_TCSETA 0x5402
%define SYS_FBIOGET_VSCREENINFO 0x4600

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
%define SYS_IXON 0x400 ; enable output flow control
%define SYS_IXOFF 0x1000 ; enable input flow control

; termios output flags
%define SYS_OPOST 0x1 ; enable ouput processing

; termios control flags
%define SYS_CSIZE 0x30 ; character size mask
%define SYS_CS5 0x0	; 5 bits (pseudo)
%define SYS_CS6 0x10	; 6 bits
%define SYS_CS7 0x20	; 7 bits
%define SYS_CS8 0x30	; 8 bits
%define SYS_PARENB 0x100 ; parity enable

; termios local flags
%define SYS_ECHO 0x8 ; enable echoing
%define SYS_ECHONL 0x40 ; echo newline even if ECHO is off
%define SYS_ICANON 0x2 ; canonicalize input lines
%define SYS_ISIG 0x1 ; enable INTR, QUIT, (D)SUSP signals
%define SYS_IEXTEN 0x8000 ; enable DISCARD and LNEXT

; lseek modes
%define SYS_SEEK_SET 0 ; seek offset relative to file start
%define SYS_SEEK_CUR 1 ; seek offset relative to current position
%define SYS_SEEK_END 2 ; seek offset relative to file end

; input events & mouse device
%define SYS_MOUSE_REL_X 0x00
%define SYS_MOUSE_REL_Y 0x01
%define SYS_MOUSE_REL_WHEEL 0x08
%define SYS_MOUSE_BTN_LEFT 0x110
%define SYS_MOUSE_BTN_RIGHT 0x111
%define SYS_MOUSE_BTN_MIDDLE 0x112
%define SYS_EVENT_SYN_REPORT 0x00
%define SYS_SYN_EVENT 0x00
%define SYS_KEY_EVENT 0x01

; pointer to argc at program start
%define SYS_ARGC_START_POINTER rsp

%macro SYS_PUSH_SYSCALL_CLOBBERED_REGISTERS 0
	push rcx
	push r11
%endmacro

%macro SYS_POP_SYSCALL_CLOBBERED_REGISTERS 0
	pop r11
	pop rcx
%endmacro
