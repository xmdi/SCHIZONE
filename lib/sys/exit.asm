%ifndef EXIT
%define EXIT

exit:	; void exit(byte {dil});

	mov rax,SYS_EXIT
	syscall

%endif
