.global hamming_weight, negate_first_k, bring_balance_to_the_word, read_input

.section .bss
.lcomm path, 1024

.section .text
read_input:
  pushq %rdi # save the input (codeword) on the stack before changing it.
  lea path(%rip), %rdi # put the address of path into rdi in order to call get_path function
  call get_path
  movq %rax, %rdi # use the return value from previous function to get file address 
  # pushq %rax # save path for later use
  movq $2, %rax # command code to OPEN is 2
  movq $0, %rsi # open for READ ONLY
  syscall # sys_open
  
  movq %rax, %rdi # use return value from sys_open to get file address
  popq %rsi # get codeword address from stack!
  pushq %rax # save file descriptor for later in order to close file
  pushq %rsi # resave codeword address on stack!
  movq $0, %rax # command code to READ is 0
  movq $128, %rdx # number of bit to read, this is a potential error/fault because there may not be this many bits to read
  syscall # sys_read
  movq (%rsi), %rdx

  xor %r9,%r9 # clear %r9
  xor %rcx,%rcx # clear %r9
  movq $128, %r9 # %r9 will hold the number of bits the number takes up
  NUMBER_LOOP:
    cmp $0xa,%dl # compare byte
    je END_NUMBER_LOOP
    movb %dl, %cl
    ror $8, %rcx
    ror $8, %rdx
    sub $8, %r9
    jmp NUMBER_LOOP # if we have reached the end of the number then by all means stop.
  END_NUMBER_LOOP:
    /*shl $8, %rcx # convert number into null terminated string!
    ror $16, %rcx*/
    # shl $8, %rcx # convert number into null terminated string!
    # the null terminated string that holds our number is in %rcx
  FIX_NUMBER:
    cmp $0, %cl
    jne END_FIX_LOOP
    shr $8, %rcx
    jmp FIX_NUMBER
  END_FIX_LOOP:
  xor %r10, %r10
  movq $128, %r10
  sub %r9, %r10 # calculate offset and then add 8 to it to account for the end of line character
  add $8, %r10

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
    imul $8, %rdx # number of bits to read
    syscall # sys_read

    
    movq (%rsi), %r9 # for debugging
    
  END_READ_DATA:
  # now that we have read this file we need to close it
    popq %rax
    syscall # sys_close
    popq %rax
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

