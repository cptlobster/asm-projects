#***************************************
#
# Name: Dustin Thomas
# Email: stdio@cptlobster.dev
# Course: CS350
# Assignment: Project 2
# Summary of Assignment Purpose: Make a small roguelike game
# Date of Initial Creation: 2023-11-17
#
# Description of Program Purpose: Maintain data integrity
#
# Functions and Modules in this file:
#   Function/Module Name: parse_input
#   Summary of Purpose: Parse the input character into player movement offset
#   Input/Stored Value Requirements: An ASCII value in $a0
#   Values Stored/Returned: Either an offset number in $v0, or the terminate bit set (0x10000041)
#
#   Function/Module Name: copy_map
#   Summary of Purpose: Copy the source map into the dynamic map address
#   Input/Stored Value Requirements: 64 bit map stored at 0x10002000
#   Values Stored/Returned: 64 bit map stored at 0x10000000, initial player position in $v0
#
#   Function/Module Name: print_map
#   Summary of Purpose: Print the map to console
#   Input/Stored Value Requirements: 64 bit map stored at 0x10000000
#   Values Stored/Returned: Map printed to console
#
#   Function/Module Name: init_player
#   Summary of Purpose: Save player position to memory
#   Input/Stored Value Requirements: The index in $a0
#   Values Stored/Returned: Stores to player position (0x10000041)
#
#   Function/Module Name: update_state
#   Summary of Purpose: Handle all state updates
#   Input/Stored Value Requirements: The offset from current position, in $a0
#   Values Stored/Returned: Updates position in memory (0x10000041)
#
#   Function/Module Name: main
#   Summary of Purpose: Run the game
#   Input/Stored Value Requirements: A map in 0x10002000-0x1000203F, user control
#   Values Stored/Returned: The game window, to console
#
#
# Additional Required Files: None
#
#***************************************
.data 0x10000000
# this is where our dynamic map data is stored
# 0x1000000 - 0x1000003F
dynmap: .space 64
# terminate condition (0x10000040)
end: .byte 0
# player position (0x10000041)
px: .byte 0

.data 0x10002000
# this is where our static map data is stored
# (0x10002000 to 0x10002040)
.ascii " ##  ###"
.ascii "       *"
.ascii "       #"
.ascii "# ###  #"
.ascii "        "
.ascii "   #### "
.ascii "   #    "
.ascii "S ## ## "
.data 0x10004000
# Initial prompt (0x10004000)
Pinit: .asciiz "WASD to move, T to terminate"
.align 4
# End prompt (0x10004020)
Pend: .asciiz "Game end."
.align 4
# Newline spam (0x10004030)
Pdeath: .asciiz "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"

.text


parse_input:
        andi $a0, $a0, 0xFFDF # lowercase to uppercase mask
        # to explain this line better:
        # LOWER             --> UPPER
        # 64  d (0110 0100) --> 44  D (0100 0100)
        # 69  i (0110 1001) --> 49  I (0100 1001)
        # We can just ignore the 6th bit (0x0020) in the ASCII
        # value and it will give us the same letter, lowercase
        # or uppercase. This simplifies our branching logic.

        ### The easy way out ###
        addi $t1, $zero, 0x0054 # T for Terminate

        bne $t1, $a0, parse_input_wasd # if not T, then parse WASD
        add $zero, $zero, $zero # NOP

        lui $t9, 0x1000       # set terminate byte
        ori $t9, $t9, 0x0040
        
        addi $t0, $zero, 1    # what we want it to be

        sb $t0, 0($t9)        # store it
        add $zero, $zero, $zero # NOP

parse_input_wasd:
        # how we will represent directions:
        # UP (W)    => -8
        # LEFT (A)  => -1
        # RIGHT (S) => 1
        # DOWN (D)  => 8
        # This is based on the memory address offset for the player's position

        or $v0, $zero, $zero    # clear $v0

        addi $t1, $zero, 0x0057 # W (up)
        beq $a0, $t1, parse_input_w
        add $zero, $zero, $zero # NOP

        addi $t1, $zero, 0x0041 # A (left)
        beq $a0, $t1, parse_input_a
        add $zero, $zero, $zero # NOP

        addi $t1, $zero, 0x0053 # S (down)
        beq $a0, $t1, parse_input_s
        add $zero, $zero, $zero # NOP

        addi $t1, $zero, 0x0044 # D (right)
        beq $a0, $t1, parse_input_d
        add $zero, $zero, $zero # NOP

        j parse_input_return  # if none of those, just skip
        add $zero, $zero, $zero # NOP

parse_input_w:
        addi $v0, $zero, -8   # up (offset memory address by -8)

        j parse_input_return
        add $zero, $zero, $zero # NOP

parse_input_a:
        addi $v0, $zero, -1   # left (offset memory address by -1)

        j parse_input_return
        add $zero, $zero, $zero # NOP

parse_input_d:
        addi $v0, $zero, 1    # right (offset memory address by 1)

        j parse_input_return
        add $zero, $zero, $zero # NOP

parse_input_s:
        addi $v0, $zero, 8    # down (offset memory address by 8)

parse_input_return: # jump to this after input checks
        jr $ra        # this is a stub!
        add $zero, $zero, $zero # NOP


copy_map: # initial map copy function
        ### setup addresses ###
        lui $s0, 0x1000      # create our source memory address
        ori $s0, $s0, 0x2000
        lui $s1, 0x1000      # create our destination memory address

        ori $t9, $zero, 64   # iterator register

        or $v0, $zero, $zero # clear our result (initial player position)

        ### loop through our memory ###
copy_map_loop:
        lb $t0, 0($s0)       # load map value
        add $zero, $zero, $zero # NOP
        sb $t0, 0($s1)       # store map value
        add $zero, $zero, $zero # NOP

        ori $t1, 0x0053
        xor $t8, $t0, $t1    # xor it, we'll only get zero if the byte matches

        bne $t8, $zero, copy_map_skip_pos # if it equals zero, we set the position value
        add $zero, $zero, $zero # NOP

copy_map_set_pos:
        or $v0, $zero, $zero  # clear our result (initial player position)

        add $v0, $zero, $s1   # add in our byte position
        andi $v0, $v0, 0x00ff # get rid of the upper part of our address

copy_map_skip_pos:
        addi $s0, $s0, 1     # next byte
        addi $s1, $s1, 1
        addi $t9, $t9, -1    # increment our iterator
        bne $t9, $zero, copy_map_loop # if iterator is not zero, go back
        add $zero, $zero, $zero # NOP

        ### end our loop ###
        jr $ra               # escape this hell
        add $zero, $zero, $zero # NOP


print_map: # map print function
        ### setup addresses ###
        lui $s0, 0x1000      # create our source memory address

        ori $t9, $zero, 64   # iterator register

        ### get player value ###
        lui $s1, 0x1000      # to match against the address
        lb $t8, 65($s0)      # pull the player position
        add $zero, $zero, $zero # NOP
        or $s1, $s1, $t8     # or in the player position

        ### loop through our memory ###
print_map_loop:
        lb $t8, 0($s0)       # load map value
        add $zero, $zero, $zero # NOP

        ori $v0, $zero, 11   # syscall 11 (print character)
        # if the current position is the player position, we use the player character
        # otherwise, we go to the map character
        or $a0, $zero, $t8   # get the byte

        bne $s0, $s1, print_map_skip_player_char
        add $zero, $zero, $zero # NOP

        ori $a0, $zero, 0x0021 # show the player (!)

print_map_skip_player_char:
        syscall

        addi $s0, $s0, 1     # next byte

        andi $t0, $s0, 7     # check if this is an 8
        bne $t0, $zero, print_map_skip_nl # if it's not, skip newline
        add $zero, $zero, $zero # NOP

        ori $a0, $zero, 10   # newline
        syscall

print_map_skip_nl: # call this label to skip the newline
        addi $t9, $t9, -1    # increment our iterator
        bne $t9, $zero, print_map_loop # if iterator is not zero, go back
        add $zero, $zero, $zero # NOP

        ### end our loop ###
        jr $ra               # escape this hell
        add $zero, $zero, $zero # NOP

init_player: # player position should be provided by copy_map
        lui $t0, 0x1000
        ori $t0, 0x0041       # player position address

        sb $a0, 0($t0)        # store the player position
        add $zero, $zero, $zero # NOP

        jr $ra                # escape
        add $zero, $zero, $zero # NOP


update_state: # player position should be provided by parse_input
        lui $t0, 0x1000       # this is our base array address, offset from this

        ### load player position ###
        lb $s0, 0x0041($t0)   # load original player position
        add $zero, $zero, $zero # NOP

        ### move the player ###
        add $s1, $s0, $a0     # add the position value to $s0

        ### check that the move is valid ###
        ### in bounds? 0 <= position < 64 ###
        slti $t9, $s1, 0      # if new position < 0, don't move
        slti $t8, $s1, 64     # if new position < 64, move

        xori $t8, $t8, 1      # flip $t8, so we can or
        or $s2, $t8, $t9      # if either condition is true, invalid move

        ### if moving left/right, against left/right edge of stage? ###

        andi $t2, $s1, 8      # get 8 from new position
        andi $t3, $s0, 8      # get 8 from old position
        xor $t2, $t2, $t3     # if they are not equal, we need to check what movement is made

        beq $t2, $zero, update_state_skip_lr_check
        add $zero, $zero, $zero # NOP

        # absolute value
        slt $t3, $a0, $zero   # if negative, we do math
        beq $t3, $zero, update_state_skip_abs
        add $zero, $zero, $zero # NOP

        sub $t5, $zero, $a0   # subtract the negative value from zero

        j update_state_abs_done
        add $zero, $zero, $zero # NOP

update_state_skip_abs:
        or $t5, $zero, $a0    # copy the positive value into $t5

update_state_abs_done:
        slti $t3, $t5, 8      # determine if $t5 is less than 8

        or $s2, $s2, $t3      # or it with our existing condition

update_state_skip_lr_check:
        ### load target map cell ###
        lui $t1, 0x1000
        add $t1, $t0, $s1     # add player offset
        lb $s3, 0($t1)        # load target map cell
        add $zero, $zero, $zero # NOP

        ori $t5, $zero, 0x0023 # pound sign (wall)
        # if not a wall, skip setting our if check
        bne $s3, $t5, update_state_not_wall
        add $zero, $zero, $zero # NOP

        ori $s2, $zero, 1     # set our if check to 1

update_state_not_wall:
        ori $t5, $zero, 0x002a # asterisk (win)
        # if not a wall, skip termination
        bne $s3, $t5, update_state_not_win
        add $zero, $zero, $zero # NOP

        ori $t5, $zero, 1

        lui $t6, 0x1000
        ori $t6, $t6, 0x0040  # terminate byte
        sw $t5, 0($t6)        # store our terminate bit
        add $zero, $zero, $zero # NOP

update_state_not_win:

        # if any of the above conditions is true, don't save the new position
        bne $s2, $zero, update_state_skip_move
        add $zero, $zero, $zero # NOP

        sb $s1, 0x0041($t0)   # store updated player position
        add $zero, $zero, $zero # NOP

update_state_skip_move:
        jr $ra                # back to the mainloop
        add $zero, $zero, $zero # NOP



main:   #### push ra to stack ####
        addi $sp, $sp, -4     # make room in stack
        sw $ra, 0($sp)        # store kernel return address in stack
        add $zero, $zero, $zero # NOP

        ### setup game state ###
        jal copy_map          # copy initial map
        add $zero, $zero, $zero # NOP

        or $a0, $zero, $v0    # copy initial position to argument
        jal init_player       # set initial player position in memory
        add $zero, $zero, $zero # NOP

        lui $a0, 0x1000       # spam newlines
        ori $a0, 0x4030
        ori $v0, $zero, 4     # syscall 4 (print string)
        syscall

        lui $a0, 0x1000       # load prompt
        ori $a0, 0x4000
        ori $v0, $zero, 4     # syscall 4 (print string)
        syscall

        ori $a0, $zero, 0x000a # newline
        ori $v0, $zero, 11    # syscall 11 (print character)
        syscall

        ### game mainloop ###
mainloop:
        jal print_map          # print the map
        add $zero, $zero, $zero # NOP

        ### read the input character ###
        ori $v0, $zero, 12     # syscall 12 (read character)
        syscall

        ### print a newline ###
        or $s0, $zero, $v0     # move the character from the function registers

        ori $v0, $zero, 11     # syscall 11 (print character)
        ori $a0, $zero, 10     # newline
        syscall

        or $a0, $zero, $s0     # move the character to $a0 for parsing

        ### parse input character ###
        jal parse_input        # parse the input character
        add $zero, $zero, $zero # NOP

        or $a0, $zero, $v0     # move the position offset to $a0

        ### update game state ###
        jal update_state       # update state based on position offset
        add $zero, $zero, $zero # NOP
        
        lui $a0, 0x1000       # spam newlines
        ori $a0, 0x4030
        ori $v0, $zero, 4     # syscall 4 (print string)
        syscall

        ### check if terminate condition is true ###
        lui $t1, 0x1000
        ori $t1, $t1, 0x0040  # address for terminate bit (0x10000040)
        lb $t0, 0($t1)        # load terminate
        add $zero, $zero, $zero

        beq $t0, $zero, mainloop # resume if terminate is zero
        add $zero, $zero, $zero # NOP

        ### Print game end string ###
        lui $a0, 0x1000       # game end string
        ori $a0, 0x4020
        ori $v0, $zero, 4     # syscall 4 (print string)
        syscall

        #### bring our normal return address back ####
        lw $ra, 0($sp)        # load main $ra from stack
        add $zero, $zero, $zero # NOP
        addi $sp, $sp, 4      # "remove" return address from stack

        jr $ra
        add $zero, $zero, $zero # NOP
