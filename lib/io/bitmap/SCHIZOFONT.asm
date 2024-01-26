%ifndef FONT_SCHIZOFONT
%define FONT_SCHIZOFONT

SCHIZOFONT:
;	Literally just a font. Each character is an 8x8 bit array (quadword).
;	ASCII values from space (32) thru tilde (126) and unknown last character.

.space:
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
.exclamation_mark:
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00000000
	db 0b00010000
	db 0b00000000
.quotation_mark:
	db 0b00101000
	db 0b00101000
	db 0b00101000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
.octothorpe:
	db 0b00000000
	db 0b00100100
	db 0b01111110
	db 0b00100100
	db 0b00100100
	db 0b01111110
	db 0b00100100
	db 0b00000000
.money:
	db 0b00010000
	db 0b00111000
	db 0b01010100
	db 0b00110000
	db 0b00011000
	db 0b01010100
	db 0b00111000
	db 0b00010000
.percent:
	db 0b01100000
	db 0b01100010
	db 0b00000100
	db 0b00001000
	db 0b00010000
	db 0b00100000
	db 0b01000110
	db 0b00000110
.ampersand:
	db 0b00110000
	db 0b01001000
	db 0b01001000
	db 0b00110000
	db 0b01010100
	db 0b01001000
	db 0b00110100
	db 0b00000000
.apostrophe:
	db 0b00100000
	db 0b00100000
	db 0b00100000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
.left_parenthesis:
	db 0b00010000
	db 0b00100000
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b00100000
	db 0b00010000
	db 0b00000000
.right_parenthesis:
	db 0b01000000
	db 0b00100000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00100000
	db 0b01000000
	db 0b00000000
.asterisk:
	db 0b00010000
	db 0b01010100
	db 0b00111000
	db 0b01111100
	db 0b00111000
	db 0b01010100
	db 0b00010000
	db 0b00010000
.plus:
	db 0b00000000
	db 0b00010000
	db 0b00010000
	db 0b01111100
	db 0b00010000
	db 0b00010000
	db 0b00000000
	db 0b00000000
.comma:
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00110000
	db 0b00110000
	db 0b01000000
.minus:
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b01111100
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
.period:
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b01100000
	db 0b01100000
	db 0b00000000
.forward_slash:
	db 0b00000000
	db 0b00000100
	db 0b00001000
	db 0b00010000
	db 0b00100000
	db 0b01000000
	db 0b00000000
	db 0b00000000
.0:
	db 0b0011100
	db 0b01000100
	db 0b01001100
	db 0b01010100
	db 0b01100100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.1:
	db 0b00010000
	db 0b00110000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00111000
	db 0b00000000
.2:
	db 0b00111000
	db 0b01000100
	db 0b00000100
	db 0b00111000
	db 0b01000000
	db 0b01000000
	db 0b01111100
	db 0b00000000
.3:
	db 0b00111000
	db 0b01000100
	db 0b00000100
	db 0b00011000
	db 0b00000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.4:
	db 0b00001000
	db 0b00011000
	db 0b00101000
	db 0b01001000
	db 0b01111100
	db 0b00001000
	db 0b00001000
	db 0b00000000
.5:
	db 0b01111100
	db 0b01000000
	db 0b01111000
	db 0b00000100
	db 0b00000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.6:
	db 0b00011000
	db 0b00100000
	db 0b01000000
	db 0b01111000
	db 0b01000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.7:
	db 0b01111100
	db 0b00000100
	db 0b00001000
	db 0b00010000
	db 0b00100000
	db 0b01000000
	db 0b01000000
	db 0b00000000
.8:
	db 0b00111000
	db 0b01000100
	db 0b01000100
	db 0b00111000
	db 0b01000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.9:
	db 0b00111000
	db 0b01000100
	db 0b01000100
	db 0b00111100
	db 0b00000100
	db 0b00001000
	db 0b00110000
	db 0b00000000
.colon:
	db 0b00000000
	db 0b00000000
	db 0b00110000
	db 0b00110000
	db 0b00000000
	db 0b00110000
	db 0b00110000
	db 0b00000000
.semicolon:
	db 0b00000000
	db 0b00000000
	db 0b00110000
	db 0b00110000
	db 0b00000000
	db 0b00110000
	db 0b00110000
	db 0b00100000
.less_than:
	db 0b00001000
	db 0b00010000
	db 0b00100000
	db 0b01000000
	db 0b00100000
	db 0b00010000
	db 0b00001000
	db 0b00000000
.equals:
	db 0b00000000
	db 0b00000000
	db 0b01111100
	db 0b00000000
	db 0b01111100
	db 0b00000000
	db 0b00000000
	db 0b00000000
.greater_than:
	db 0b01000000
	db 0b00100000
	db 0b00010000
	db 0b00001000
	db 0b00010000
	db 0b00100000
	db 0b01000000
	db 0b00000000
.question_mark:
	db 0b00111000
	db 0b01000100
	db 0b00000100
	db 0b00001000
	db 0b00010000
	db 0b00000000
	db 0b00010000
	db 0b00000000
.at:
	db 0b00111000
	db 0b01000100
	db 0b00000100
	db 0b00110100
	db 0b01010100
	db 0b01010100
	db 0b00111000
	db 0b00000000
.A:
	db 0b00010000
	db 0b00101000
	db 0b01000100
	db 0b01000100
	db 0b01111100
	db 0b01000100
	db 0b01000100
	db 0b00000000
.B:
	db 0b01111000
	db 0b01000100
	db 0b01000100
	db 0b01111000
	db 0b01000100
	db 0b01000100
	db 0b01111000
	db 0b00000000
.C:
	db 0b00111000
	db 0b01000100
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01000100
	db 0b00111000
	db 0b00000000
.D:
	db 0b01111000
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01111000
	db 0b00000000
.E:
	db 0b01111100
	db 0b01000000
	db 0b01000000
	db 0b01110000
	db 0b01000000
	db 0b01000000
	db 0b01111100
	db 0b00000000
.F:
	db 0b01111100
	db 0b01000000
	db 0b01000000
	db 0b01110000
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b00000000
.G:
	db 0b00111100
	db 0b01000000
	db 0b01000000
	db 0b01001100
	db 0b01000100
	db 0b01000100
	db 0b00111100
	db 0b00000000
.H:
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01111100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b00000000
.I:
	db 0b00111000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00111000
	db 0b00000000
.J:
	db 0b00000100
	db 0b00000100
	db 0b00000100
	db 0b00000100
	db 0b00000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.K:
	db 0b01000100
	db 0b01001000
	db 0b01010000
	db 0b01100000
	db 0b01010000
	db 0b01001000
	db 0b01000100
	db 0b00000000
.L:
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01111100
	db 0b00000000
.M:
	db 0b01000100
	db 0b01101100
	db 0b01010100
	db 0b01010100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b00000000
.N:
	db 0b01000100
	db 0b01100100
	db 0b01010100
	db 0b01001100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b00000000
.O:
	db 0b00111000
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.P:
	db 0b01111000
	db 0b01000100
	db 0b01000100
	db 0b01111000
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b00000000
.Q:
	db 0b00111000
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01010100
	db 0b01001000
	db 0b00110100
	db 0b00000000
.R:
	db 0b01111000
	db 0b01000100
	db 0b01000100
	db 0b01111000
	db 0b01010000
	db 0b01001000
	db 0b01000100
	db 0b00000000
.S:
	db 0b00111000
	db 0b01000100
	db 0b01000000
	db 0b00111000
	db 0b00000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.T:
	db 0b01111100
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00000000
.U:
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.V:
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b00101000
	db 0b00101000
	db 0b00010000
	db 0b00010000
	db 0b00000000
.W:
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01010100
	db 0b01010100
	db 0b01101100
	db 0b01000100
	db 0b00000000
.X:
	db 0b01000100
	db 0b01000100
	db 0b00101000
	db 0b00010000
	db 0b00101000
	db 0b01000100
	db 0b01000100
	db 0b00000000
.Y:
	db 0b01000100
	db 0b01000100
	db 0b00101000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00000000
.Z:
	db 0b01111100
	db 0b00000100
	db 0b00001000
	db 0b00010000
	db 0b00100000
	db 0b01000000
	db 0b01111100
	db 0b00000000
.left_square_bracket:
	db 0b01110000
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01110000
	db 0b00000000
.back_slash:
	db 0b00000000
	db 0b01000000
	db 0b00100000
	db 0b00010000
	db 0b00001000
	db 0b00000100
	db 0b00000000
	db 0b00000000
.right_square_bracket:
	db 0b0111000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b01110000
	db 0b00000000
.caret:
	db 0b00010000
	db 0b00101000
	db 0b01000100
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
.underscore:
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b01111100
	db 0b00000000
.tick:
	db 0b01000000
	db 0b00100000
	db 0b00010000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
.a:
	db 0b00000000
	db 0b00000000
	db 0b00111000
	db 0b00000100
	db 0b00111100
	db 0b01000100
	db 0b00111100
	db 0b00000000
.b:	
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01111000
	db 0b01000100
	db 0b01000100
	db 0b01111000
	db 0b00000000
.c:
	db 0b00000000
	db 0b00000000
	db 0b00111000
	db 0b01000100
	db 0b01000000
	db 0b01000100
	db 0b00111000
	db 0b00000000
.d:
	db 0b00000100
	db 0b00000100
	db 0b00000100
	db 0b00111100
	db 0b01000100
	db 0b01000100
	db 0b00111100
	db 0b00000000
.e:
	db 0b00000000
	db 0b00000000
	db 0b00111000
	db 0b01000100
	db 0b01111100
	db 0b01000000
	db 0b00111000
	db 0b00000000
.f:
	db 0b00010000
	db 0b00101000
	db 0b00100000
	db 0b01110000
	db 0b00100000
	db 0b00100000
	db 0b00100000
	db 0b00000000

.g:
	db 0b00000000
	db 0b00000000
	db 0b00111000
	db 0b01000100
	db 0b00111100
	db 0b00000100
	db 0b01000100
	db 0b00111000
.h:
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01111000
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b00000000
.i:
	db 0b00000000
	db 0b00100000
	db 0b00000000
	db 0b01100000
	db 0b00100000
	db 0b00100000
	db 0b0111000
	db 0b00000000
.j:
	db 0b00000000
	db 0b00000100
	db 0b00000000
	db 0b00000100
	db 0b00000100
	db 0b00000100
	db 0b01000100
	db 0b00111000
.k:
	db 0b01000000
	db 0b01000000
	db 0b01001000
	db 0b01010000
	db 0b01100000
	db 0b01010000
	db 0b01001000
	db 0b00000000
.l:
	db 0b01100000
	db 0b00100000
	db 0b00100000
	db 0b00100000
	db 0b00100000
	db 0b00100000
	db 0b01110000
	db 0b00000000
.m:
	db 0b00000000
	db 0b00000000
	db 0b01101000
	db 0b01010100
	db 0b01010100
	db 0b01010100
	db 0b01010100
	db 0b00000000
.n:
	db 0b00000000
	db 0b00000000
	db 0b01110000
	db 0b01001000
	db 0b01001000
	db 0b01001000
	db 0b01001000
	db 0b00000000
.o:
	db 0b00000000
	db 0b00000000
	db 0b00111000
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.p:
	db 0b00000000
	db 0b00000000
	db 0b01111000
	db 0b01000100
	db 0b01000100
	db 0b01111000
	db 0b01000000
	db 0b01000000
.q:
	db 0b00000000
	db 0b00000000
	db 0b00111100
	db 0b01000100
	db 0b01000100
	db 0b00111100
	db 0b00000100
	db 0b00000100
.r:
	db 0b00000000
	db 0b00000000
	db 0b01111000
	db 0b01000100
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b00000000
.s:
	db 0b00000000
	db 0b00000000
	db 0b01111000
	db 0b10000000
	db 0b01111000
	db 0b00000100
	db 0b01111000
	db 0b00000000
.t:
	db 0b00010000
	db 0b00010000
	db 0b01111100
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00001000
	db 0b00000000
.u:
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.v:
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b01000100
	db 0b01000100
	db 0b00101000
	db 0b00010000
	db 0b00000000
.w:
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b01000100
	db 0b01010100
	db 0b01010100
	db 0b00101000
	db 0b00000000
.x:
	db 0b00000000
	db 0b00000000
	db 0b01000100
	db 0b00101000
	db 0b00010000
	db 0b00101000
	db 0b01000100
	db 0b00000000
.y:
	db 0b00000000
	db 0b00000000
	db 0b01000100
	db 0b01000100
	db 0b00111100
	db 0b00000100
	db 0b01000100
	db 0b00111000
.z:
	db 0b00000000
	db 0b00000000
	db 0b01111100
	db 0b00001000
	db 0b00010000
	db 0b00100000
	db 0b01111100
	db 0b00000000
.left_curly_bracket:
	db 0b00010000
	db 0b00100000
	db 0b00100000
	db 0b01000000
	db 0b00100000
	db 0b00100000
	db 0b00010000
	db 0b00000000
.pipe:
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00000000
.right_curly_bracket:
	db 0b01000000
	db 0b00100000
	db 0b00100000
	db 0b00010000
	db 0b00100000
	db 0b00100000
	db 0b01000000
	db 0b00000000
.tilde:
	db 0b00000000
	db 0b00000000
	db 0b00100000
	db 0b01010100
	db 0b00001000
	db 0b00000000
	db 0b00000000
	db 0b00000000
.unknown:
	db 0b11111111
	db 0b11101111
	db 0b11101111
	db 0b10000011
	db 0b11101111
	db 0b11101111
	db 0b11101111
	db 0b11111111

%endif