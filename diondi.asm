;##################################################
;################## CODE RAPHAEL ##################
;##################################################
extern printf

section .data
	a_x: db	14
	a_y: db 20
	b_x: db 25
	b_y: db 69
	c_x: db 10
	c_y: db 60
	format: db "Res : %d", 10, 0

section .text
global main
main:
	mov ah, [a_x]
	mov al, [a_y]
	mov bh, [b_x]
	mov bl, [b_y]
	sub ah, bh
	sub al, bl
	mov ch, [c_x]
	mov cl, [c_y]
	sub ch, bh
	sub cl, bl
	movsx dx, ah
	movsx bx, cl
	imul dx, bx
	movsx si, al
	movsx cx, ch
	imul cx, si
	sub dx, cx

	push rbp
	mov rdi, format
	movsx rsi, dx
	mov rdx, 0
	mov rax, 0
	call printf

	pop rbp

	mov rax, 60
	mov rdi, 0
	syscall
	ret
