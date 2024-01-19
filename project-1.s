#***************************************
#
# Name: Dustin Thomas
# Email: stdio@cptlobster.dev
# Course: CS350
# Assignment: Project 1
# Summary of Assignment Purpose: Implement a system for using Hamming encoding
# Date of Initial Creation: 2023-10-30
#
# Description of Program Purpose: Maintain data integrity
#
# Functions and Modules in this file:
#   Function/Module Name: encode
#   Summary of Purpose: Encode Hamming encoded data to raw bits
#   Input/Stored Value Requirements: 16 bit encoded string via console
#   Values Stored/Returned: Data bits output to console
#
#   Function/Module Name: encode
#   Summary of Purpose: Encode data using Hamming parity
#   Input/Stored Value Requirements: 11 bits input via console
#   Values Stored/Returned: Encoded bits output to console
#
#   Function/Module Name: getpb
#   Summary of Purpose: Check for even parity in a sequence.
#   Input/Stored Value Requirements: A word in $a0
#   Values Stored/Returned: 1 or 0, in $v0
#
#   Function/Module Name: parser
#   Summary of Purpose: Parse a string of 1's and 0's into a number
#   Input/Stored Value Requirements: Memory address for start of string
#   Values Stored/Returned: A number in $v0
#
#   Function/Module Name: err_p
#   Summary of Purpose: Handle parser errors
#   Input/Stored Value Requirements: None
#   Values Stored/Returned: Print error to console
#
#   Function/Module Name: printb
#   Summary of Purpose: Print bytes to the console
#   Input/Stored Value Requirements: A word in $a0 (16 bits)
#   Values Stored/Returned: Bytes output to console
#
#   Function/Module Name: main
#   Summary of Purpose: Main program loop
#   Input/Stored Value Requirements: Either "e", "d", or "t" input
#   Values Stored/Returned: None; calls other functions
#
#
# Additional Required Files: None
#
#***************************************
.data 0x10000000
# input codeword (0x10000000)
Din:    .word 0
# raw data extracted (0x10000004)
Draw:   .word 0
.align 2
# parity bits
Dp8:    .byte 0  # 0x10000008
Dp4:    .byte 0  # 0x10000009
Dp2:    .byte 0  # 0x1000000a
Dp1:    .byte 0  # 0x1000000b
Dpt:    .byte 0  # 0x1000000c
.align 2
Dsyn:   .byte 0  # 0x10000010
# corrected codeword
Dcorr:  .word 0  # 0x10000014
# final output data
Dfinal: .word 0  # 0x10000018
.data 0x10004000
### INITIAL MENU ###
# 0x10004000
Pinit:  .asciiz "OPTIONS\ne: Encode\nd: Decode\nt: Terminate\n"
.align 3
### PROMPTS ###
# 0x10004030
Psel:   .asciiz "Select option: "
.align 3
# 0x10004040
Pdata:  .asciiz "Enter data: "
.align 3
### RESULT IDENTIFIERS ###
# 0x10004050
Psyn:   .asciiz "Hamming Syn.: "
.align 3
# 0x10004060
Pcorr:  .asciiz "Fixed codeword: "
.align 3
# 0x10004078
Pres:   .asciiz "Result: "
.align 3
### PARITY IDENTIFIERS ###
# 0x10004088
Ptot:   .asciiz "Total parity? "
.align 2
# 0x10004098
Ptpass: .asciiz "YES"
.align 2
# 0x1000409c
Ptfail: .asciiz "NO"
.align 3
### VALIDITY ###
# 0x100040a0
Pnoe:   .asciiz "Codeword valid!"
.align 3
# 0x100040b0
Ponee:  .asciiz "1 error found."
.align 3
# 0x100040c0
Ptwoe:  .asciiz "2 errors found."
### ERROR MESSAGES ###
.align 3
# 0x100040d0
Pberr:  .asciiz "Must be 1 or 0 only"
.align 3
# 0x100040e8
Perr:   .asciiz "Must be e, d, or t"
.align 3
# 0x10004100
Pterr:  .asciiz "Cannot fix 2 errors"
.align 3
### EXIT MESSAGE ###
# 0x10004118
Pexit:  .asciiz "Have a nice day! :^)"
### PARITY BIT PREPEND:
.align 3
# 0x10004130
Pp8:    .asciiz "P8="
.align 2
# 0x10004134
Pp4:    .asciiz "P4="
.align 2
# 0x10004138
Pp2:    .asciiz "P2="
.align 2
# 0x1000413c
Pp1:    .asciiz "P1="
.align 2
# 0x10004140
Ppt:    .asciiz "PT="

.text

decode: ### prompt user for bits ###
        ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load data prompt (Pdata)
        ori $a0, 0x4040
        syscall

        ori $v0, $zero, 8     # syscall 8 (read string)
        lui $a0, 0x1000       # set address of input buffer
        ori $a0, $a0, 0x2000
        ori $a1, $zero, 17    # set length to 17 bytes
        syscall

        ### parse the input string ###
        addi $sp, $sp, -4     # make room in stack
        sw $ra, 0($sp)        # store kernel return address in stack
        add $zero, $zero, $zero # NOP

        jal parser            # call the parser to get the input string
        add $zero, $zero, $zero # NOP

        or $s0, $zero, $v0    # copy $v0 out since the syscall will overwrite it

        lw $ra, 0($sp)        # load main $ra from stack
        add $zero, $zero, $zero # NOP
        addi $sp, $sp, 4      # "remove" return address from stack

        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        ### get parity bits ###
        addi $sp, $sp, -4     # make room in stack
        sw $ra, 0($sp)        # store main return address in stack
        add $zero, $zero, $zero # NOP

        # for this section, use:
        # $s1: raw data, spaced out
        # $a0: masked bits
        # $t9: for storing memory addresses

        ## p8 ##
        andi $a0, $s0, 0xFF00 # p8 mask
        jal getpb             # call the parity bit function
        add $zero, $zero, $zero # NOP

        lui $t9, 0x1000       # set to raw input
        sb $v0, 8($t9)        # store parity in memory
        add $zero, $zero, $zero # NOP

        ## p4 ##
        andi $a0, $s0, 0xF0F0 # p4 mask
        jal getpb             # call the parity bit function
        add $zero, $zero, $zero # NOP

        lui $t9, 0x1000       # set to raw input
        sb $v0, 9($t9)        # store parity in memory
        add $zero, $zero, $zero # NOP

        ## p2 ##
        andi $a0, $s0, 0xCCCC # p2 mask
        jal getpb             # call the parity bit function
        add $zero, $zero, $zero # NOP

        lui $t9, 0x1000       # set to raw input
        sb $v0, 10($t9)       # store parity in memory
        add $zero, $zero, $zero # NOP

        ## p1 ##
        andi $a0, $s0, 0xAAAA # p1 mask
        jal getpb             # call the parity bit function
        add $zero, $zero, $zero # NOP

        lui $t9, 0x1000       # set to raw input
        sb $v0, 11($t9)       # store parity in memory
        add $zero, $zero, $zero # 
        
        ### reload main return address ###
        lw $ra, 0($sp)        # load main $ra from stack
        add $zero, $zero, $zero # NOP
        addi $sp, $sp, 4      # "remove" return address from stack

        ### create the syndrome, and print bits as we go ###

        # use:
        # $t7: for storing the hamming syndrome
        # $s2: for storing the value we copy into $s0
        # $s0: for storing the spaced out data
        # $a0: for storing parity bits temporarily

        # newline first
        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        ### p8
        ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load data prompt (Pp8)
        ori $a0, 0x4130
        syscall

        # load from memory
        lui $t9, 0x1000       # set to raw input
        lb $a0, 8($t9)        # get p8
        add $zero, $zero, $zero # NOP

        ori $v0, $zero 1      # syscall 1 (print integer)
        syscall
        
        # hamming syndrome
        or $t7, $zero, $a0    # add in our parity bit to hamming syndrome
        sll $t7, $t7, 1       # shift left for next parity bit

        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        ### p4
        ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load data prompt (Pp4)
        ori $a0, 0x4134
        syscall

        # load from memory
        lui $t9, 0x1000       # set to raw input
        lb $a0, 9($t9)        # get p4
        add $zero, $zero, $zero # NOP

        ori $v0, $zero, 1     # syscall 1 (print integer)
        syscall
        
        # hamming syndrome
        or $t7, $t7, $a0      # add in our parity bit to hamming syndrome
        sll $t7, $t7, 1       # shift left for next parity bit

        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        ### p2
        ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load data prompt (Pp2)
        ori $a0, 0x4138
        syscall

        # load from memory
        lui $t9, 0x1000       # set to raw input
        lb $a0, 10($t9)       # get p2
        add $zero, $zero, $zero # NOP

        ori $v0, $zero 1      # syscall 1 (print integer)
        syscall
        
        # hamming syndrome
        or $t7, $t7, $a0      # add in our parity bit to hamming syndrome
        sll $t7, $t7, 1       # shift left for next parity bit

        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        ### p1
        ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load data prompt (Pp1)
        ori $a0, 0x413C
        syscall

        # load from memory
        lui $t9, 0x1000       # set to raw input
        lb $a0, 11($t9)       # get p1
        add $zero, $zero, $zero # NOP

        ori $v0, $zero 1      # syscall 1 (print integer)
        syscall
        
        # hamming syndrome
        or $t7, $t7, $a0      # add in our parity bit to hamming syndrome

        # parity bits that match empty space
        sll $a0, $a0, 1       # prep to insert in data
        or $s2, $s2, $a0

        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        ### store syndrome in memory ###
        lui $t9, 0x1000       # set to address of syndrome (0x10000010)
        ori $t9, $t9, 16

        sw $t7, 0($t9)        # store our syndrome in memory
        add $zero, $zero, $zero # NOP

        or $a0, $s2, $s0      # combine our parity bits with our spaced data

        sw $a0, 8($t9)        # store our data in memory
        add $zero, $zero, $zero # NOP

        # as it stands now:
        # $a0: our data
        # $s1: our hamming syndrome
        ### calculate total parity ###
        or $s0, $zero, $a0    # move the value with parity into $s0

        addi $sp, $sp, -4     # make room in stack
        sw $ra, 0($sp)        # store main return address in stack
        add $zero, $zero, $zero # NOP

        # for this section, use:
        # $s1: raw data, spaced out
        # $a0: masked bits
        # $t9: for storing memory addresses

        ## pt ##
        andi $a0, $s0, 0xFFFF # pt mask
        jal getpb             # call the parity bit function
        add $zero, $zero, $zero # NOP

        lui $t9, 0x1000       # set to raw input
        sb $v0, 12($t9)       # store parity in memory
        add $zero, $zero, $zero # NOP

        or $t7, $zero, $v0    # copy parity over

        lw $ra, 0($sp)        # load main $ra from stack
        add $zero, $zero, $zero # NOP
        addi $sp, $sp, 4      # "remove" return address from stack

        ### move the bit into the main return value ###

        # use:
        # $t7: for storing the hamming syndrome
        # $s2: for storing the value we copy into $s0
        # $s0: for storing the spaced out data
        # $a0: for storing parity bits temporarily

        # newline first
        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        ### pt
        ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load data prompt (Ppt)
        ori $a0, 0x4140
        syscall

        # load from memory
        lui $t9, 0x1000       # set to raw input
        lb $a0, 12($t9)        # get pt
        add $zero, $zero, $zero # NOP

        ori $v0, $zero 1      # syscall 1 (print integer)
        syscall

        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        ### check for errors ###

        lui $t9, 0x1000       # set to address of syndrome (0x10000010)
        ori $t9, $t9, 16

        lw $t8, 0($t9)        # load syndrome into t8
        add $zero, $zero, $zero # NOP
        lb $t7, -4($t9)       # load total parity into t7
        add $zero, $zero, $zero # NOP

        ### branch that soulja boy ###
        bne $t7, $zero, err1  # if total parity != 0, branch to 1 error
        add $zero, $zero, $zero
        bne $t8, $zero, err2  # if syndrome != 0 and pt = 0, 2 errors
        add $zero, $zero, $zero
        j err0                # else, zero errors! yipee

err1:   ori $t1, $zero, 1     # bit we shall flip
e1loop: beq $t8, $zero, e1le  # if 0, branch to the end
        add $zero, $zero, $zero # NOP
        sll $t1, $t1, 1       # shift left 1
        addi $t8, $t8, -1     # count down
        j e1loop              # go back to the beginning
        add $zero, $zero, $zero # NOP

e1le:   xor $s0, $s0, $t1     # flip the singular bit

        ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load message (Ponee)
        ori $a0, 0x40b0
        syscall

        j copy2               # end it
        add $zero, $zero, $zero # NOP

err2:   ori $s0, $zero, 0xFFFF # value is useless, get rid of it

        ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load message (Ptwoe)
        ori $a0, 0x40c0
        syscall

        lui $t9, 0x1000       # set to address of syndrome (0x10000010)
        ori $t9, $t9, 16

        sw $s0, 8($t9)        # store our data in memory
        add $zero, $zero, $zero # NOP

        j copy1               # end it
        add $zero, $zero, $zero # NOP

err0:   ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load message (Pnoe)
        ori $a0, 0x40a0
        syscall

        j copy2               # end it
        add $zero, $zero, $zero # NOP

copy2:  lui $t9, 0x1000       # set to address of syndrome (0x10000010)
        ori $t9, $t9, 16

        sw $s0, 8($t9)        # store our data in memory
        add $zero, $zero, $zero # NOP

        or $a0, $zero, $s0

        # newline first
        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        ### print the output string ###
        addi $sp, $sp, -4     # make room in stack
        sw $ra, 0($sp)        # store kernel return address in stack
        add $zero, $zero, $zero # NOP

        jal printb            # call the printer to print the decoded string
        add $zero, $zero, $zero # NOP

        lw $ra, 0($sp)        # load main $ra from stack
        add $zero, $zero, $zero # NOP
        addi $sp, $sp, 4      # "remove" return address from stack

        or $s1, $zero, $s0

        ### adjust spacing for parity bits ###
        andi $t0, $s1, 0xFE00 # get the first 7 bits (0000 0*** **** 0000)
        srl $t0, $t0, 5       # shift them to the left (**** ***0 0000 0000)
        or $s0, $zero, $t0    # put in temporary register (**** ***0 0000 0000)

        andi $t0, $s1, 0x00E0 # get the next 3 bits (0000 0000 0000 ***0)
        srl $t0, $t0, 4       # shift them to the left (0000 0000 ***0 0000)
        or $s0, $s0, $t0      # put in temporary register (**** ***0 ***0 0000)

        andi $t0, $s1, 0x0008 # get the last bit (0000 0000 0000 000*)
        srl $t0, $t0, 3       # shift it to the left (0000 0000 0000 *000)
        or $s0, $s0, $t0      # put in temporary register (**** ***0 ***0 *000)

copy1:  # newline first
        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        lui $t9, 0x1000       # set to address of syndrome (0x10000010)
        ori $t9, $t9, 16

        sw $s0, 12($t9)        # store our data in memory
        add $zero, $zero, $zero # NOP

        or $a0, $zero, $s0

        ### print the output string ###
        addi $sp, $sp, -4     # make room in stack
        sw $ra, 0($sp)        # store kernel return address in stack
        add $zero, $zero, $zero # NOP

        jal printb            # call the printer to print the decoded string
        add $zero, $zero, $zero # NOP

        lw $ra, 0($sp)        # load main $ra from stack
        add $zero, $zero, $zero # NOP
        addi $sp, $sp, 4      # "remove" return address from stack

        jr $ra
        add $zero, $zero, $zero # NOP

encode: ### prompt user for bits ###
        ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load data prompt (Pdata)
        ori $a0, 0x4040
        syscall

        ori $v0, $zero, 8     # syscall 8 (read string)
        lui $a0, 0x1000       # set address of input buffer
        ori $a0, $a0, 0x2000
        ori $a1, $zero, 12    # set length to 12 bytes
        syscall

        ### parse the input string ###
        addi $sp, $sp, -4     # make room in stack
        sw $ra, 0($sp)        # store kernel return address in stack
        add $zero, $zero, $zero # NOP

        jal parser            # call the parser to get the input string
        add $zero, $zero, $zero # NOP

        or $s1, $zero, $v0    # copy $v0 out since the syscall will overwrite it

        lw $ra, 0($sp)        # load main $ra from stack
        add $zero, $zero, $zero # NOP
        addi $sp, $sp, 4      # "remove" return address from stack

        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        ### shove our input data into memory ###
        lui $t9, 0x1000       # set to raw input
        sw $s1, 0($t9)        # store initial value in memory
        add $zero, $zero, $zero # NOP
        sw $s1, 0($t9)        # store in raw data entry
        add $zero, $zero, $zero # NOP

        ### adjust spacing for parity bits ###
        andi $t0, $s1, 0x07F0 # get the first 7 bits (0000 0*** **** 0000)
        sll $t0, $t0, 5       # shift them to the left (**** ***0 0000 0000)
        or $s0, $zero, $t0    # put in temporary register (**** ***0 0000 0000)

        andi $t0, $s1, 0x000E # get the next 3 bits (0000 0000 0000 ***0)
        sll $t0, $t0, 4       # shift them to the left (0000 0000 ***0 0000)
        or $s0, $s0, $t0      # put in temporary register (**** ***0 ***0 0000)

        andi $t0, $s1, 1      # get the last bit (0000 0000 0000 000*)
        sll $t0, $t0, 3       # shift it to the left (0000 0000 0000 *000)
        or $s0, $s0, $t0      # put in temporary register (**** ***0 ***0 *000)

        ### get parity bits ###
        addi $sp, $sp, -4     # make room in stack
        sw $ra, 0($sp)        # store main return address in stack
        add $zero, $zero, $zero # NOP

        # for this section, use:
        # $s1: raw data, spaced out
        # $a0: masked bits
        # $t9: for storing memory addresses

        ## p8 ##
        andi $a0, $s0, 0xFF00 # p8 mask
        jal getpb             # call the parity bit function
        add $zero, $zero, $zero # NOP

        lui $t9, 0x1000       # set to raw input
        sb $v0, 8($t9)        # store parity in memory
        add $zero, $zero, $zero # NOP

        ## p4 ##
        andi $a0, $s0, 0xF0F0 # p4 mask
        jal getpb             # call the parity bit function
        add $zero, $zero, $zero # NOP

        lui $t9, 0x1000       # set to raw input
        sb $v0, 9($t9)        # store parity in memory
        add $zero, $zero, $zero # NOP

        ## p2 ##
        andi $a0, $s0, 0xCCCC # p2 mask
        jal getpb             # call the parity bit function
        add $zero, $zero, $zero # NOP

        lui $t9, 0x1000       # set to raw input
        sb $v0, 10($t9)       # store parity in memory
        add $zero, $zero, $zero # NOP

        ## p1 ##
        andi $a0, $s0, 0xAAAA # p1 mask
        jal getpb             # call the parity bit function
        add $zero, $zero, $zero # NOP

        lui $t9, 0x1000       # set to raw input
        sb $v0, 11($t9)       # store parity in memory
        add $zero, $zero, $zero # 
        
        ### reload main return address ###
        lw $ra, 0($sp)        # load main $ra from stack
        add $zero, $zero, $zero # NOP
        addi $sp, $sp, 4      # "remove" return address from stack

        ### create the syndrome, and print bits as we go ###

        # use:
        # $t7: for storing the hamming syndrome
        # $s2: for storing the value we copy into $s0
        # $s0: for storing the spaced out data
        # $a0: for storing parity bits temporarily

        # newline first
        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        ### p8
        ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load data prompt (Pp8)
        ori $a0, 0x4130
        syscall

        # load from memory
        lui $t9, 0x1000       # set to raw input
        lb $a0, 8($t9)        # get p8
        add $zero, $zero, $zero # NOP

        ori $v0, $zero 1      # syscall 1 (print integer)
        syscall
        
        # hamming syndrome
        or $t7, $zero, $a0    # add in our parity bit to hamming syndrome
        sll $t7, $t7, 1       # shift left for next parity bit

        # parity bits that match empty space
        sll $a0, $a0, 8       # prep to insert in data
        or $s2, $zero, $a0

        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        ### p4
        ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load data prompt (Pp4)
        ori $a0, 0x4134
        syscall

        # load from memory
        lui $t9, 0x1000       # set to raw input
        lb $a0, 9($t9)        # get p4
        add $zero, $zero, $zero # NOP

        ori $v0, $zero, 1     # syscall 1 (print integer)
        syscall
        
        # hamming syndrome
        or $t7, $t7, $a0      # add in our parity bit to hamming syndrome
        sll $t7, $t7, 1       # shift left for next parity bit

        # parity bits that match empty space
        sll $a0, $a0, 4       # prep to insert in data
        or $s2, $s2, $a0

        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        ### p2
        ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load data prompt (Pp2)
        ori $a0, 0x4138
        syscall

        # load from memory
        lui $t9, 0x1000       # set to raw input
        lb $a0, 10($t9)       # get p2
        add $zero, $zero, $zero # NOP

        ori $v0, $zero 1      # syscall 1 (print integer)
        syscall
        
        # hamming syndrome
        or $t7, $t7, $a0      # add in our parity bit to hamming syndrome
        sll $t7, $t7, 1       # shift left for next parity bit

        # parity bits that match empty space
        sll $a0, $a0, 2       # prep to insert in data
        or $s2, $s2, $a0

        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        ### p1
        ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load data prompt (Pp1)
        ori $a0, 0x413C
        syscall

        # load from memory
        lui $t9, 0x1000       # set to raw input
        lb $a0, 11($t9)       # get p1
        add $zero, $zero, $zero # NOP

        ori $v0, $zero 1      # syscall 1 (print integer)
        syscall
        
        # hamming syndrome
        or $t7, $t7, $a0      # add in our parity bit to hamming syndrome

        # parity bits that match empty space
        sll $a0, $a0, 1       # prep to insert in data
        or $s2, $s2, $a0

        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        ### store syndrome in memory ###
        lui $t9, 0x1000       # set to address of syndrome (0x10000010)
        ori $t9, $t9, 16

        sw $t8, 0($t9)        # store our syndrome in memory
        add $zero, $zero, $zero # NOP

        or $a0, $s2, $s0      # combine our parity bits with our spaced data

        sw $a0, 8($t9)        # store our data in memory
        add $zero, $zero, $zero # NOP

        # as it stands now:
        # $a0: our data
        # $s1: our hamming syndrome
        ### calculate total parity ###
        or $s0, $zero, $a0    # move the value with parity into $s0

        addi $sp, $sp, -4     # make room in stack
        sw $ra, 0($sp)        # store main return address in stack
        add $zero, $zero, $zero # NOP

        # for this section, use:
        # $s1: raw data, spaced out
        # $a0: masked bits
        # $t9: for storing memory addresses

        ## pt ##
        andi $a0, $s0, 0xFFFF # pt mask
        jal getpb             # call the parity bit function
        add $zero, $zero, $zero # NOP

        lui $t9, 0x1000       # set to raw input
        sb $v0, 12($t9)       # store parity in memory
        add $zero, $zero, $zero # NOP

        lw $ra, 0($sp)        # load main $ra from stack
        add $zero, $zero, $zero # NOP
        addi $sp, $sp, 4      # "remove" return address from stack

        ### move the bit into the main return value ###

        # use:
        # $t7: for storing the hamming syndrome
        # $s2: for storing the value we copy into $s0
        # $s0: for storing the spaced out data
        # $a0: for storing parity bits temporarily

        # newline first
        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        ### pt
        ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load data prompt (Ppt)
        ori $a0, 0x4140
        syscall

        # load from memory
        lui $t9, 0x1000       # set to raw input
        lb $a0, 12($t9)        # get pt
        add $zero, $zero, $zero # NOP

        ori $v0, $zero 1      # syscall 1 (print integer)
        syscall

        # parity bits that match empty space
        or $s2, $zero, $a0

        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        or $a0, $s2, $s0      # combine our parity bits with our spaced data

        sw $a0, 8($t9)        # store our data in memory
        add $zero, $zero, $zero # NOP
        sw $a0, 12($t9)        # store our data in memory
        add $zero, $zero, $zero # NOP

        ### print the output string ###
        addi $sp, $sp, -4     # make room in stack
        sw $ra, 0($sp)        # store kernel return address in stack
        add $zero, $zero, $zero # NOP

        jal printb            # call the printer to print the decoded string
        add $zero, $zero, $zero # NOP

        lw $ra, 0($sp)        # load main $ra from stack
        add $zero, $zero, $zero # NOP
        addi $sp, $sp, 4      # "remove" return address from stack

        jr $ra
        add $zero, $zero, $zero # NOP

getpb:  or $v0, $zero, $zero # clear our output
        or $t0, $zero, $a0   # pull our value in
        beq $t0, $zero, bkend # if n = 0, skip forward
        add $zero, $zero, $zero # NOP
        ### Brian Kernighan's Algorithm loop ###
bkloop: addi $t1, $t0, -1    # get n - 1
        and $t0, $t0, $t1    # n = n && n - 1
        addi $v0, $v0, 1     # add 1 to the count
        bne $t0, $zero, bkloop # if n != 0, do it again
        add $zero, $zero, $zero # NOP
        ### get odd or even
bkend:  andi $v0, $v0, 1     # get the last bit only
        ### End loop ###
        jr $ra               # we're done, get me out
        add $zero, $zero, $zero # NOP


parser: or $t0, $zero, $a0    # copy memory address
        or $v0, $zero, $zero  # clear $v0, so we can save our result to it
        ### start parsing the input string ###
par_l:  lb $t1, 0($t0)        # read value from memory
        add $zero, $zero, $zero # NOP
        beq $t1, $zero, par_e # If null terminator, return
        add $zero, $zero, $zero # NOP

        sll $v0, $v0, 1       # shift our return value left 1 to fit the next bit
        addi $t1, $t1, -48    # subtract 48 from the ASCII value

        sltiu $t2, $t1, 2     # if t1 < 2, it's either 0 or 1
        beq $t2, $zero, err_p # otherwise, we error out
        add $v0, $v0, $t1     # add t1 to our target
        addi $t0, $t0, 1      # add a byte 
        j par_l               # go back to the beginning of the loop
        add $zero, $zero, $zero # NOP
        ### get me out ###
par_e:  jr $ra
        add $zero, $zero, $zero # NOP

err_p:  ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load parser error (Pberr)
        ori $a0, 0x40d0
        syscall

        lw $ra, 0($sp)        # load main $ra from stack
        add $zero, $zero, $zero # NOP
        addi $sp, $sp, 4      # "remove" return address from stack

        or $v0, $zero, $zero
        j resume              # escape back to main loop
        add $zero, $zero, $zero # NOP

printb: ori $s0, $zero, 16    # setup our iterator
        or $t0, $zero, $a0    # copy $a0 out
prt_l:  andi $t2, $t0, 0x8000 # mask the last bit

        srl $t2, $t2, 15      # shift the test bit all the way to the right
                              # we get either 1 or 0 this way
        
        ori $v0, $zero, 11    # syscall 11 (print char)
        addi $a0, $t2, 0x0030 # add our true/false bit to the ASCII value of 0
        syscall

        sll $t0, $t0, 1       # shift $t0 left 1 bit
        addi $s0, $s0, -1     # reduce length by 1
        bne $s0, $zero, prt_l # if length left is not zero, go back to the beginning
        add $zero, $zero, $zero # NOP

        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        jr $ra                # get me out
        add $zero, $zero, $zero # NOP



main:   ### Main loop ###
        ### Prompt User ###
        ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load initial prompt (Pinit)
        ori $a0, 0x4000
        syscall

        lui $a0, 0x1000       # load char prompt (Psel)
        ori $a0, 0x4030
        syscall

        ori $v0, $zero, 12    # syscall 12 (read character)
        syscall

        or $t0, $zero, $v0    # store character in $t0

        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        andi $t0, $t0, 0xFFDF # lowercase to uppercase mask
        # to explain this line better:
        # LOWER             --> UPPER
        # 64  d (0110 0100) --> 44  D (0100 0100)
        # 69  i (0110 1001) --> 49  I (0100 1001)
        # We can just ignore the 6th bit (0x0020) in the ASCII
        # value and it will give us the same letter, lowercase
        # or uppercase. This simplifies our branching logic.
        ### The easy way out ###
        addi $t1, $zero, 0x0054 # T for Terminate
        beq $t0, $t1, exit    # skip all the annoying stack stuff if T
        add $zero, $zero, $zero # NOP

        #### push ra to stack ####
        addi $sp, $sp, -4     # make room in stack
        sw $ra, 0($sp)        # store kernel return address in stack
        add $zero, $zero, $zero # NOP

        addi $t1, $zero, 0x0045 # E for Encode
        beq $t0, $t1, c_enc # call encode function
        add $zero, $zero, $zero # NOP

        addi $t1, $zero, 0x0044 # D for Decode
        beq $t0, $t1, c_dec # call decode function
        add $zero, $zero, $zero # NOP
        
        ### raise error if not valid input
        ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load error prompt
        ori $a0, 0x40e8
        syscall

        ori $v0, $zero, 11    # syscall 11 (print character)
        ori $a0, $zero, 10    # Newline
        syscall

        j resume              # skip the rest of the functions
        add $zero, $zero, $zero # NOP

c_enc:  ### call encoder function ###
        jal encode
        add $zero, $zero, $zero # NOP
        j resume              # skip the rest of the functions
        add $zero, $zero, $zero # NOP

        ### call decoder function ###
c_dec:  jal decode
        add $zero, $zero, $zero # NOP

        #### bring our normal return address back ####
resume: lw $ra, 0($sp)        # load main $ra from stack
        add $zero, $zero, $zero # NOP
        addi $sp, $sp, 4      # "remove" return address from stack

        j main                # start all over again

exit:   ori $v0, $zero, 4     # syscall 4 (print string)
        lui $a0, 0x1000       # load exit prompt
        ori $a0, 0x4118
        syscall               # Have a nice day! :)

        jr $ra                # let the robots take over
        add $zero, $zero, $zero # NOP
