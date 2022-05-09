.global hamming_weight, negate_first_k, bring_balance_to_the_word, read_input

.section .bss
.lcomm path, 1024

.section .text
read_input:
  pushq %rdi # save the input on the stack before changing it.

  lea path(%rip), %rdi # put the address of path into rdi in order to call get_path function
  # maybe save the register that has a return address on the stack
  call get_path
  movq %rax, %rdi # use the return value from previous function to get file address 
  movq $2, %rax # command code to OPEN is 2
  movq $0, %rsi # open for READ ONLY
  call sys_open

  # allocate a new variable to hold what we want to read from the file
  subq $8, %rsp
  subq $8, %rbp # necessary?
  movq %rbp, %rsi # %rsi now holds the address of the variable we just allocated
  movq $0, %rax # command code to READ is 0
  movq $8, %rdx # number of bit to read
  call sys_read

  movq (%rsi), %rdx # save what you read from the file before deallocating
  addq $8, %rsp # free the memory you allocated
  addq $8, %rbp # free the memory you allocated

  number_loop:
    shr $1, %rdx
    cmp $0xa,%cl
    je end_loop # if we have reached the end of the number then by all means stop.
    jmp number_loop # otherwise keep going in a loop until you reach the end
  end_loop:
    shl $1, %rdx # convert number into null terminated string!

  movq %rdx, %rax # why?
  call atam_atol
  movq %rax, %rdx # move the actual number's value into %rdx when you're done!

  popq %r10 # %r10 now holds the address of codeword which we saved on the stack in the beginning
  lea path(%rip), %r11 # %r11 now holds the address of the text we want to read
  add $8, %r11 # wrooooooooooooooooooooooooooooooooooooooong!!!
  # you should align the address with that of the one right after the line break which is after the line you read!

  read_loop:
    cmp $0, %rdx # %rdx has the number of bytes we want to read.
    je end_read_loop
    subq $8, %rsp
    subq $8, %rbp # necessary?
    movq %rbp, %rsi # %rsi now holds the address of the variable we just allocated
    movq $0, %rax # command code to READ is 0
    movq $8, %rdx # number of bit to read
    call sys_read
    sub $8, %rdx
    addq $8, %rsp # free the memory you allocated
    addq $8, %rbp # free the memory you allocated 
    movq (%rsi),%r12
    movq %r12, (%rdi)
    add $1, %rdi
    jmp read_loop

  end_read_loop:
  ret

get_path:
  movq (%rdi), %r8
  shr 1, %r8 # remove line ending
  movq %r8, %rax # put the return value inside %rax
  ret

atam_atol:
  xor %rcx, %rcx # %rcx now holds the number (we want to return at the end)
  xor %rbx, %rbx # rbx holds the base we're multiplying by (raised to a power)
  inc %rbx # %rbxx++
  shr $1, %rdx # removes the null at end
  calc_loop:
    shr $1, %rdx # get last digit
    cmp $0, %cl
    je end_loop
    sub $48, %cl
    xor %r8, %r8
    mov %cl, %r8
    imulb %rbx, %r8
    add %r8, %rcx
    imul $16, %rbx
  end_loop:
    movq %rcx, %rax # %rax now holds the final return value!
  ret

hamming_weight:
  # %rdi holds the array and %rsi hold the length of the array
  imulq $8, %rsi # %rsi now holds the number of bytes!
  imulq $8, %rsi # %rsi now holds the number of bits!
  # movq $0, %rbx # number of 0's counter, unnecessary?
  movq $0, %rax # number of 1's counter
  xor %rdx, %rdx
  movb (%rdi), %dl
  movq $0, %r8 # shifted bits counter
  movq $0, %r9 # shifted bits counter modulo 9
  
  CALCULATION_LOOP:
    cmp %rsi, %r8 # checks if we have counted all bits
    jge EXIT
    cmp $8, %r9
    jge CHANGE_BYTE
    shr $1, %dl
    inc %r8
    inc %r9
    cmp $1, %cl
    jl CALCULATION_LOOP
    add $1, %rax
    jmp CALCULATION_LOOP
  CHANGE_BYTE:
    add $1, %rdi
    movb (%rdi), %dl
    jmp CALCULATION_LOOP
  EXIT:
  ret

negate_first_k:
  # %rdi holds codeword, and %rsi holds k
  movq %rdi, %rax
  movq %rsi, %rdx
  dec %rdx
  movq $1, %rbx
  NOT_LOOP:
    xor %rbx, %rax
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
  movq $0 %r9 # %r9 holds the index we stopped at which is 0 at the beginning
  BALANCE_LOOP:
    cmp $0, %rdx
    je RESET_VALUES
    COMEBACK_AFTER_RESET:
      call hamming_weight
      movq %rax, %r8
      movq %rsi %rax
      idiv %r8
      cmp $2 , %rax
      je BALANCED
      NOT_LOOP:
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
  movq $63 %rdx
  jmp COMEBACK_AFTER_RESET

  BALANCED:
  movq %r9, %rax # index we stopped at as a return value!
  ret

