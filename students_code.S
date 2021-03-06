.global hamming_weight, negate_first_k, bring_balance_to_the_word, read_input

.section .bss
.lcomm path, 1024

.section .text
read_input: # passed initial check
  pushq %rdi # save the input (codeword) on the stack before changing it.
  lea path(%rip), %rdi # put the address of path into rdi in order to call get_path function
  call get_path
  movq %rax, %rdi # use the return value from previous function to get file address 
  movq $2, %rax # command code to OPEN is 2
  movq $0, %rsi # open for READ ONLY
  syscall # sys_open
  
  movq %rax, %rdi # use return value from sys_open to get file address
  popq %rsi # get codeword address from stack!
  pushq %rax # save file descriptor for later in order to close file
  pushq %rsi # resave codeword address on stack!
  movq $0, %rax # command code to READ is 0
  movq $8, %rdx # number of bytes! to read, this is a potential error/fault because there may not be this many bits to read
  syscall # sys_read
  movq (%rsi), %rdx

  xor %r9,%r9 # clear %r9
  xor %rcx,%rcx # clear %r9
  movq $8, %r9 # %r9 will hold the number of bytes the number takes up
  NUMBER_LOOP:
    cmp $0xa,%dl # compare byte
    je END_NUMBER_LOOP
    movb %dl, %cl
    ror $8, %rcx
    ror $8, %rdx
    sub $1, %r9
    jmp NUMBER_LOOP # if we have reached the end of the number then by all means stop.
  END_NUMBER_LOOP:
    
  FIX_NUMBER:
    cmp $0, %cl
    jne END_FIX_LOOP
    shr $8, %rcx
    jmp FIX_NUMBER
  END_FIX_LOOP:
  xor %r10, %r10
  movq $8, %r10
  sub %r9, %r10 # calculate offset and then add 1byte to it to account for the end of line character
  add $1, %r10 # account for the end of line character

  # refetch codeword address from the stack!
  popq %rdi
  pushq %rdi
  pushq %r10 # save the offset on the stack so that we use it while reading later!
  movq %rcx, (%rdi) # conventions
  call atam_atol
  movq %rax, %rcx # move the actual number's value into %rdx when you're done!
  movq $8, %r8
  xor %rdx,%rdx
  idiv %r8
  movq %rcx, %rdx # just for now because above we moved %rax into %rcx and now changed it to %rcx because of idiv
  # %rax now holds the return value

  popq %r10 # %r10 now holds the offset from the beginning of the file we want to read from.
  popq %rsi # %rsi now holds the address of codeword
  popq %rdi # %rdi now holds the file descriptor
  pushq %rax # save the return value for the function on the stack to return later
  pushq %rdi # resave file descriptor on the stack
  READ_DATA:
    cmp $0, %rdx # %rdx has the number of bytes we want to read.
    je END_READ_DATA
    movq $0x11, %rax # command code to READ at an offset is 0x11
    syscall # sys_read
    
  END_READ_DATA: # now that we have read this file we need to close it
    popq %rax
    syscall # sys_close
    popq %rax
  ret


hamming_weight: # passed initial check
  # pay attention : we have 2 return values, the number of 1's in %rax and the number of 0's in %rdx
  # %rdi holds the array and %rsi hold the length of the array
  /*pushq %r12 # save according to conventions
  pushq %r13 # save according to conventions*/
  movq $0, %rax # number of 1's counter
  xor %rdx, %rdx
  xor %rcx, %rcx
  movq (%rdi), %r11 # %r11 now holds the first quad of (%rdi)
  movq $0, %r8 # shifted bits counter, potential bug with counting!!!!!!!!!!!!!!
  jmp CALCULATION_LOOP

  ADD_ONE_TO_ZEROS_COUNTER:
    add $1, %rdx
  CALCULATION_LOOP:
    cmp $0, %rsi # checks if we have counted all bits(throughout all quads)
    je EXIT
    cmp $64, %r8 # checks if we have counted all bits in current quad    jge CHANGE_BYTE
    je CHANGE_QUAD
    shr $1, %r11
    inc %r8
    jnc ADD_ONE_TO_ZEROS_COUNTER
    add $1, %rax
    jmp CALCULATION_LOOP
  CHANGE_QUAD:
    dec %rsi
    add $8, %rdi
    movq (%rdi), %r11
    movq $0, %r8
    jmp CALCULATION_LOOP
  EXIT:
    /*popq %r13
    popq %r12*/
  ret

negate_first_k:
  # %rdi holds codeword, and %rsi holds k
  pushq %rbx # this register is callee save
  movq %rdi, %rax
  movq %rsi, %rdx
  movq $1, %rbx
  NOT_LOOP:
    xor %rbx, %rax
    dec %rdx # potential bug with indexes
    cmp $0, %rdx
    je  END_NOT_LOOP
    imul $2, %rbx
    jmp NOT_LOOP
  END_NOT_LOOP:
  popq %rbx # restore pervious value
  ret

bring_balance_to_the_word:
  # %rdi hold a pointer to codeword, %rsi holds len
  pushq %r12 # callee saved
  pushq %r13 # callee saved
  movq %rdi, %r12 # save it for later use in hamming_weight
  movq %rsi, %r13 # save it for later use in hamming_weight
  xor %rax,%rax # for the index we stop at which is 0 at the beginning
  movq $1, %rbx # for xor purposes
  xor %rdx, %rdx # for calculating which quad we should be in!
  
  BALANCE_LOOP:
    pushq %rax
    pushq %rdx
    pushq %rcx
    pushq %rsi
    pushq %rdi
    # %rbx is callee saved therefore we don't have to save it
    # pass proper parameters to %rsi and %rdi
    movq %r12, %rdi
    movq %r13, %rsi
    call hamming_weight
    cmp %rax, %rdx
    je BALANCED # if the 0's an 1's are equal the word is balanced!
    popq %rdi
    popq %rsi
    popq %rcx
    popq %rdx
    popq %rax
    PERFORM_NOT_ON_K:
      xor %rbx, (%rdi)
      add $1, %rax
      add $1, %rdx
      cmp $64, %rdx
      je RESET_VALUES
      imul $2, %rbx
      jmp BALANCE_LOOP

  RESET_VALUES:
  add $8, %rdi
  dec %rsi
  cmp $0, %rsi
  je EXIT_BALANCE # there are no more bytes to flip!
  movq $0, %rdx
  movq $1, %rbx # restart process for new quad!
  jmp BALANCE_LOOP

  BALANCED:
    popq %rdi
    popq %rsi
    popq %rcx
    popq %rdx
    popq %rax
    popq %r13 # callee saved
    popq %r12 # callee saved
  EXIT_BALANCE:
  ret

