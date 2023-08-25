%ifndef PARSE_DELIMITED_FLOAT_FILE
%define PARSE_DELIMITED_FLOAT_FILE

; dependencies


parse_delimited_float_file:
; void parse_delimited_float_file(double* {rdi}, uint {rsi}, uint {rdx},
;		 uint {rcx}, void* {r8}, char {r9b});
;	Reads {rdx} double-precision floating point values from the file
;	descriptor in {rsi} and places them in the array starting at
;	address {rdi}. Uses a buffer of length {rcx} starting at address
;	{r8} for this purpose. The delimiter between floats is passed in
;	{r9b}.

	; initialize break flag to zero	

	; attempt to load {rcx} bytes from {rsi} into {r8}
	; if we got less than {rcx} bytes, set a flag to break after
	;	this iteration
.read_loop:
	
	; parse starting at beginning of the buffer
.parse_loop:
	; for the remaining bytes in the buffer, calculate the offset 
	;	to the next delimited character {r9b}
	; if -1 and no break flag, shift the last piece of buffer into 
	;	the beginning and fill the buffer with additional bytes
	; 	from {rsi} (jmp to .read_loop).
	; if -1 and break flag, parse the last float
	; if >0, call parse_float and copy to the destination array,
	;	and then parse the next float (jmp to .parse_loop)
	; if no remaining bytes to parse, jmp to .read_loop.	



%endif
