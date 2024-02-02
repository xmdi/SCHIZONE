%ifndef CENTROID_SORT
%define CENTROID_SORT

; dependency
%include "lib/math/vector/distance_3.asm"

centroid_sort:
; void centroid_sort(struct* {rdi}, struct* {rsi});
; 	Sorts the array of shell bodies listed at {rdi} in order of
;	maximum distance from the viewpoint specified by the 
;	perspective structure at {rsi}.
	
%if 0	; sample perspective structure

.perspective_structure:
	dq 1.00 ; lookFrom_x	
	dq 2.00 ; lookFrom_y	
	dq 5.00 ; lookFrom_z	
	dq 0.00 ; lookAt_x	
	dq 0.00 ; lookAt_y	
	dq 2.00 ; lookAt_z	
	dq 0.0 ; upDir_x	
	dq 0.0 ; upDir_y	
	dq 1.0 ; upDir_z	
	dq 0.3	; zoom

.shell_list_structure:	; sample shell list structure to be sorted
	dq 4 ; number of structures
	dq .faces_top_structure ; address of shell body structure
	dq 0.0, 0.0, 3.5 ; centroid of shell body structure
	dq .faces_bottom_structure ; address of shell body structure
	dq 0.0, 0.0, 1.0 ; centroid of shell body structure
	dq .faces_right_structure ; address of shell body structure
	dq -1.0, 0.0, 0.0 ; centroid of shell body structure
	dq .faces_left_structure ; address of shell body structure
	dq 1.0, 0.0, 0.0 ; centroid of shell body structure

%endif

	push rax
	push rbx
	push rcx
	push rdx
	push r8
	push r9
	push r10
	push r11
	sub rsp,32
	movdqu [rsp+0],xmm0
	movdqu [rsp+16],xmm1

	mov r8,[rdi+0]
	cmp r8,1
	jbe .ret
	dec r8		; outer loop limit

	xor rcx,rcx	; outer loop counter

.outer_loop:

	mov r9,r8
	sub r9,rcx	; inner loop limit

	xor rdx,rdx	; inner loop counter

.inner_loop:

	; check if we need to swap element {rdx} and element {rdx+1}
	
	mov rax,rdx
	shl rax,5
	add rax,16
	add rax,rdi	; {rax} points to element {rdx}
	mov rbx,rax
	add rbx,32	; {rbx} points to element {rdx+1}

	push rdi
	mov rdi,rax
	call distance_3	
	movsd xmm1,xmm0 ; distance to element {rdx} in {xmm1}
	
	mov rdi,rbx
	call distance_3	; distance to element {rdx+1} in {xmm1}
	pop rdi
	
	comisd xmm0,xmm1
	jbe .no_swap
	
	; swap if necessary

	;;;;
;	jmp .no_swap

	mov r10,[rbx-8]
	mov r11,[rax-8]
	mov [rbx-8],r11
	mov [rax-8],r10

	mov r10,[rbx+0]
	mov r11,[rax+0]
	mov [rbx+0],r11
	mov [rax+0],r10
	
	mov r10,[rbx+8]
	mov r11,[rax+8]
	mov [rbx+8],r11
	mov [rax+8],r10
	
	mov r10,[rbx+16]
	mov r11,[rax+16]
	mov [rbx+16],r11
	mov [rax+16],r10

.no_swap:
	inc rdx
	cmp rdx,r9
	jb .inner_loop

	inc rcx
	cmp rcx,r8
	jb .outer_loop

.ret:
	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+16]
	add rsp,32
	pop r11
	pop r10
	pop r9
	pop r8
	pop rdx
	pop rcx
	pop rbx
	pop rax
	ret

%endif
