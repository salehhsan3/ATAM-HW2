.globl my_ili_handler

.text
.align 4, 0x90
my_ili_handler:
	# Prologue
	pushq %rbp
	movq %rsp, %rbp

	# Registers save
	pushq %rax
	pushq %rcx
	pushq %rdx
	pushq %rbx
	pushq %rsi
	pushq %rdi
	pushq %r8
	pushq %r9
	pushq %r10
	pushq %r11
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15

	# C code following the sysV ABI requires DF to be clear on function entry
	cld
	# Moving the old %rip address to %rax
	movq 8(%rbp), %rax
	# Moving the Instruction Opcode (up to 2 bytes) caused the interrupt to %di
	movzwq (%rax), %rdi
	cmpb $0x0f, %dil
	je two_bytes_opcode
	# Here we have an 1 byte opcode
	andw $0xff, %di
	call what_to_do
	movq $1, %rcx
	jmp check_return_value
	two_bytes_opcode:
	shrw $8, %di
	call what_to_do
	movq $2, %rcx

	check_return_value:
	cmpl $0, %eax
	jne exit_handler
	# Jumping to the old ili_handler
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %r11
	popq %r10
	popq %r9
	popq %r8
	popq %rdi
	popq %rsi
	popq %rbx
	popq %rdx
	popq %rcx
	popq %rax
	popq %rbp
	jmp *(old_ili_handler)

	exit_handler:
	# Make sure to land on the next instruction after we return
	addq %rcx, 8(%rbp)

	# Registers restore
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %r11
	popq %r10
	popq %r9
	popq %r8
	popq %rdi
	# Return value
	movl %eax, %edi
	popq %rsi
	popq %rbx
	popq %rdx
	popq %rcx
	popq %rax

	# Epilogue
	movq %rbp, %rsp
	popq %rbp
	iretq
