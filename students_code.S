.global hamming_weight, negate_first_k, bring_balance_to_the_word, read_input

.section .bss
.lcomm path, 1024

.section .text
read_input:
  pushq %rdi # save the input on the stack before changing it.

  lea path(%rip), %rdi # put the address of path into rdi in order to call get_path function
  call get_path
  movq %rax, %rdi # use the return value from previous function to get file address 
  movq %rax, %r13 # debugging!
  movq $2, %rax # command code to OPEN is 2
  movq $0, %rsi # open for READ ONLY
  syscall # sys_open

  movq %r13,%rdi # debugging!
  subq $8, %rsp
  subq $8, %rbp # necessary?
  movq %rbp, %rsi # %rsi now holds the address of the variable we just allocated
  movq $0, %rax # command code to READ is 0
  movq $64, %rdx # number of bit to read
  syscall # sys_read
  movq (%rsi), %r15

  # allocate a new variable to hold what we want to read from the file
  movq %r13,%rdi # debugging!
  add $8, %rdi
  subq $8, %rsp
  subq $8, %rbp # necessary?  movq %rbp, %rsi # %rsi now holds the address of the variable we just allocated
  movq %rbp, %rsi # %rsi now holds the address of the variable we just allocated
  movq $0, %rax # command code to READ is 0
  movq $64, %rdx # number of bit to read
  syscall # sys_read
  movq (%rsi), %r14

  # it was given that the number is no more than 7 digits each digit take 1 byte to write in its ASCII form
  # therefore atmost it will take 7*8=56bits for the number and 8 more for 0xa therefore it will be 64bits all around!

  movq (%rsi), %rdx # save what you read from the file before deallocating ,,,, used to be (%rsi)
  addq $16, %rsp # free the memory you allocated
  addq $16, %rbp # free the memory you allocated
  xor %r9,%r9 # clear %r9
  movq $64, %r9 # %r9 will hold the number of bits the number takes up

  NUMBER_LOOP:
    cmp $0xa,%dl # compare byte
    je END_NUMBER_LOOP
    shr $8, %rdx
    sub $8, %r9
    jmp NUMBER_LOOP # if we have reached the end of the number then by all means stop.
  END_NUMBER_LOOP:
    shr $4, %rdx # convert number into null terminated string!
    shl $4, %rdx # convert number into null terminated string!

  movq %rdx, %rdi # conventions
  call atam_atol
  movq %rax, %rdx # move the actual number's value into %rdx when you're done!
  movq $8, %r8
  idiv %r8
  # %rax now holds the return value

  popq %r10 # %r10 now holds the address of codeword which we saved on the stack in the beginning
  lea path(%rip), %r11 # %r11 now holds the address of the text we want to read
  add %r9, %r11 # making %r11 hold the address of the memory path where the actual data starts (after the number)
  movq %r11, %rdi
  # you should align the address with that of the one right after the line break which is after the line you read!

  READ_LOOP:
    cmp $0, %rdx # %rdx has the number of bytes we want to read.
    je END_READ_LOOP
    subq $8, %rsp
    subq $8, %rbp # necessary?
    movq %rbp, %rsi # %rsi now holds the address of the variable we just allocated
    movq $0, %rax # command code to READ is 0
    movq $8, %rdx # number of bit to read
    syscall # sys_read
    sub $8, %rdx
    addq $8, %rsp # free the memory you allocated
    addq $8, %rbp # free the memory you allocated 
    movq (%rsi),%r12
    movq %r12, (%rdi)
    add $1, %rdi
    jmp READ_LOOP
  END_READ_LOOP:
  # now that we have read this file we need to close it
    lea path(%rip), %rdi
    movq $3, %rax
    syscall # sys_close
  ret


hamming_weight:
  # %rdi holds the array and %rsi hold the length of the array
  movq $0, %rax # number of 1's counter
  xor %rdx, %rdx
  movq (%rdi), %rdx # %rdx now holds the first quad of (%rdi)
  movq $0, %r8 # shifted bits counter, potential bug with counting!!!!!!!!!!!!!!
  
  CALCULATION_LOOP:
    cmp $0, %rsi # checks if we have counted all bits(throughout all quads)
    jge EXIT
    cmp $64, %r8 # checks if we have counted all bits in current quad    jge CHANGE_BYTE
    jge CHANGE_QUAD
    shr $1, %rdx
    cmp $1, %cl
    jl CALCULATION_LOOP
    add $1, %rax
    jmp CALCULATION_LOOP
  CHANGE_QUAD:
    dec %rsi
    add $8, %rdi
    movq (%rdi), %rdx
    jmp CALCULATION_LOOP
  EXIT:
  ret

negate_first_k:
  # %rdi holds codeword, and %rsi holds k
  movq %rdi, %rax
  movq %rsi, %rdx
  dec %rdx # potential bug with indexes maybe it should be omitted
  movq $1, %rbx
  NOT_LOOP:
    xor %rbx, %rax
    dec %rdx # potential bug with indexes
    cmp $0, %rdx
    je  END_NOT_LOOP
    imul $2, %rbx
    jmp NOT_LOOP
  END_NOT_LOOP:
  ret

bring_balance_to_the_word:
  # %rdi hold a pointer to codeword, %rsi holds len
  xor %rax,%rax
  movq %rdi, %r10
  movq %rsi, %r11
  movq $63, %rdx
  movq $1, %rbx
  movq $0, %r9 # %r9 holds the index we stopped at which is 0 at the beginning
  BALANCE_LOOP:
    cmp $0, %rdx
    je RESET_VALUES
    COMEBACK_AFTER_RESET:
      call hamming_weight
      movq %rax, %r8
      movq %rsi, %rax
      idiv %r8
      cmp $2 , %rax
      je BALANCED
      PERFORM_NOT_ON_K:
        xor %rbx, %rcx
        imul $2, %rbx
        inc %r9
        dec %rdx
        jmp BALANCE_LOOP

  RESET_VALUES:
  add $8, %rdi
  dec %rsi
  cmp $0, %rsi
  je BALANCED # there are no more bytes to flip!
  movq $63, %rdx
  jmp COMEBACK_AFTER_RESET

  BALANCED:
  movq %r9, %rax # index we stopped at as a return value!
  ret

