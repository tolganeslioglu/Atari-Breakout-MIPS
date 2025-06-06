######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8   # Each pixel is 8x8 display units
# - Unit height in pixels:      8   # Each pixel is 8x8 display units
# - Display width in pixels:    256 # Total 32 units horizontally
# - Display height in pixels:   256 # Total 32 units vertically
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data - Constants and configuration values that don't change
##############################################################################
# Display and input addresses
ADDR_DSPL:
    .word 0x10008000          # Base address for the bitmap display
ADDR_KBRD:
    .word 0xffff0000          # Base address for keyboard input

# Color definitions
BRICK_COLOURS:
    .word 0x00f76a6a         # Red color for bricks
BACKGROUND_COLOUR:
    .word 0x00000000         # Black background
BORDER_COLOUR:
    .word 0x00ffffff         # White border
PLAYER_COLOUR:
    .word 0x00fd9701         # Orange color for paddle and ball

# Border configurations
BORDER_TOP_HEIGHT:
    .word 5                  # Height of top border in units
BORDER_SIDE_WIDTH:
    .word 2                  # Width of side borders in units
BORDER_SIDE_WIDTH_UNITS:
    .word 8                  # Width of side borders in bytes (2 units * 4 bytes)

# Paddle configuration
PADDLE_ONE:
    .word 30                 # Y-position of paddle (30 units from top)

# Game over screen and scoring
GAMEOVER_IMAGE:
    .include "gameover_image.asm"    # 32x32 game over screen image data

    .align 2  # Ensure 4-byte alignment
SCORE:
    .word 0                  # Current game score, initialized to 0

    .align 2  # Ensure alignment for strings
SCORE_LABEL:
    .asciiz "SCORE: "       # Label for score display
    
    .align 2  # Ensure alignment for next string
NEWLINE:
    .asciiz "\n"            # Newline character

    .align 2  # Ensure alignment for next data item
##############################################################################
# Mutable Data - Variables that change during gameplay
##############################################################################
# Paddle position (in bytes, where 128 bytes = 32 units)
PADDLE_ONE_LEFT:
    .word 52                # Left edge X-position of paddle
PADDLE_ONE_RIGHT:
    .word 76                # Right edge X-position of paddle

# Ball position and movement
BALL_X:
    .word 60                # Ball's X position in bytes
BALL_Y: 
    .word 28                # Ball's Y position in units (starts above paddle)

# Ball movement vectors
VEC_X:
    .word 4                 # Horizontal movement (4=right, -4=left)
VEC_Y:
    .word 1                 # Vertical movement (1=down, -1=up)

# Game configuration
GAME_SPEED:
    .word 80               # Base game speed in milliseconds (adjusts with score)
##############################################################################
# Code
##############################################################################
    .text
	.globl main

	# Run the Brick Breaker game.
main:
    # Initialize the game
    jal draw_scene
    
    jal respond_to_p                # Allow player to launch the ball upon first starting

game_loop:
	# 1a. Check if key has been pressed
	#      This code is from the handout starter code!
	lw $t0, ADDR_KBRD
    lw $t8, 0($t0)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    j input_end                     # If no input, pass
    
    # 1b. Check which key has been pressed
    keyboard_input:
        lw $a0, 4($t0)                  # Load second word from keyboard
        
        beq $a0, 0x71, respond_to_q     # If q is pressed: quit game
        beq $a0, 97, respond_to_a       # If a is pressed: move Paddle left
		beq $a0, 100, respond_to_d	    # If d is pressed: move Paddle right
		beq $a0, 112, respond_to_p	    # If p is pressed: pause game
		beq $a0, 114, restart_game      # If r is pressed: restart game
		j input_end               		# Runs if nothing passes; continue with game_loop

    # Continue with game loop
    input_end: 

        # Check collisions in all directions
        li $a0, 0          # Check top
        jal check_collision
        li $a0, 1          # Check right
        jal check_collision
        li $a0, 2          # Check bottom
        jal check_collision
        li $a0, 3          # Check left
        jal check_collision

	# 2b. Update location of ball
	play_ball:
	jal move_ball
	
	# 3. Draw the screen
	#      This is being done within our response functions!
	
	# 4. Sleep
	li $v0, 32
	lw $a0, GAME_SPEED    # Use variable game speed instead of hardcoded value
	syscall

    # 5. Go back to 1
    b game_loop
    
# =============================================================================
#                               DRAWING FUNCTIONS
# =============================================================================

# Scene drawing function
draw_scene:
    # Store current return address in stack (to go back to main)
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Fill the background
    jal fill_background
        
    # Draw the border
    jal draw_border
    
    # Draw the paddle
    lw $a0, PADDLE_ONE      # Y-value of the paddle's location
    lw $a1, PLAYER_COLOUR
    jal draw_paddle_one
    
    # Draw bricks
    jal draw_bricks
    
    # Initialize the ball
    jal draw_ball
    
    # Pop address on stack and return to main
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra

# Background filling function for pink background <3
fill_background:
    # Store current return address in stack (to go back to draw_scene)
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # 1. Define argument values for rectangle drawing function
    lw $a0, ADDR_DSPL           # $a0 = Starting location for drawing the rectangle
    addi $a1, $zero, 32         # $a1 = Width of the rectangle
    addi $a2, $zero, 32         # $a2 = Height of the rectangle
    lw $a3, BACKGROUND_COLOUR   # $a3 = Colour of the background
    
    # 2. Call rectangle drawing function
    jal draw_rect
    
    # Pop address on stack and return to draw_scene
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra
    
# Border drawing function
draw_border:
    # Store current return address in stack (to go back to draw_scene)
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Draw the top border first, with dimensions (128, BORDER_TOP_HEIGHT)
    # 1. Define argument values for rectangle drawing function
    lw $a0, ADDR_DSPL           # $a0 = Starting location for drawing the rectangle
    add $a1, $zero, 32          # $a1 = Width of the rectangle
    lw $a2, BORDER_TOP_HEIGHT   # $a2 = Height of the rectangle
    lw $a3, BORDER_COLOUR       # $a3 = Colour of the border
    # 2. Call rectangle drawing function
    jal draw_rect
    
    # Draw the left border, with dimensions (BORDER_SIDE_WIDTH, 128 - BORDER_TOP_HEIGHT)
    # 1. Define argument values for rectangle drawing function
    # 1a. Calculate starting point of left side border
    lw $t0, ADDR_DSPL           # Save ADDR_DSPL in $t0 for calculation usage
    lw $t1, BORDER_TOP_HEIGHT   # Save BORDER_TOP_HEIGHT in $t1 for calculation usage
    addi $t2, $zero, 128         # Save 128 in a register for multiplication usage
    mult $t1, $t2               # Multiply 128 and BORDER_TOP_HEIGHT to get starting value
    mflo $t3                    # Save product in $t3            
    add $t0, $t0, $t3         # Add this value to starting point
    # 1b. Get height of left side border
    sub $t4, $t2, $t1           # Subtract BORDER_TOP_HEIGHT from 128
    # 1c. Set argument values
    add $a0, $zero, $t0         # $a0 = Starting location for drawing the rectangle
    lw $a1, BORDER_SIDE_WIDTH   # $a1 = Width of the rectangle
    add $a2, $zero, $t4         # $a2 = Height of the rectangle
    lw $a3, BORDER_COLOUR       # $a3 = Colour of the border
    # 2. Call rectangle drawing function
    jal draw_rect
    
    # Draw the right border, again with dimensions (BORDER_SIDE_WIDTH, 128 - BORDER_TOP_HEIGHT)
    # 1. Define argument values for rectangle drawing function
    # 1a. Calculate starting point of right side border
    lw $t0, ADDR_DSPL           # Save ADDR_DSPL in $t0 for calculation usage
    lw $t1, BORDER_TOP_HEIGHT   # Save BORDER_TOP_HEIGHT in $t1 for calculation usage
    lw $t2, BORDER_SIDE_WIDTH   # Save BORDER_SIDE_WIDTH in $t2 for calculation usage
    lw $t7, BORDER_SIDE_WIDTH_UNITS
    addi $t3, $zero, 128        # Save 128 in $t3 for multiplication usage
    mult $t1, $t3               # Multiply 128 and BORDER_TOP_HEIGHT to get starting value
    mflo $t4                    # Save product in $t4
    add $t0, $t0, $t4           # Add this value to starting point
    sub $t5, $t3, $t7           # Subtract BORDER_SIDE_WIDTH_UNITS from 126 and save in $t5
    add $t0, $t0, $t5           # Add this value to starting point
    # 1c. Get height of left side border
    sub $t6, $t3, $t1           # Subtract BORDER_TOP_HEIGHT from 126
    # 1d. Set argument values
    add $a0, $zero, $t0         # $a0 = Starting location for drawing the rectangle
    lw $a1, BORDER_SIDE_WIDTH   # $a1 = Width of the rectangle
    add $a2, $zero, $t6         # $a2 = Height of the rectangle
    lw $a3, BORDER_COLOUR       # $a3 = Colour of the border
    # 2. Call rectangle drawing function
    jal draw_rect
    
    # Pop address on stack and return to draw_scene
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra
    
# Paddle drawing function
# Takes in the following:
# - $a0 : Row that the paddle lives in (y-value)
# - $a1 : Colour of the paddle
draw_paddle_one:
    # 1. Load in arguments
    add $t0, $zero, $a0     # Put row of paddle into $t0
    add $t4, $zero, $a1     # Load in the colour
    
    # 2. Get starting location for drawing the paddle
    lw $t1, ADDR_DSPL
    lw $t5, PADDLE_ONE_LEFT # Get x value of left side of paddle
    addi $t2, $zero, 128    # Get 128 into register for easy computation
    mult $t2, $t0           # Multiply (128 * row of paddle)
    mflo $t3                # Store product in $t3
    add $t1, $t1, $t3       # Add product to location in $t1
    add $t1, $t1, $t5       # Get starting X Value
    
    # 3. Draw paddle
    sw $t4, 0($t1)
    sw $t4, 4($t1)
    sw $t4, 8($t1)
    sw $t4, 12($t1)
    sw $t4, 16($t1)
    sw $t4, 20($t1)
    
    jr $ra

# Paddle drawing function
# Takes in the following:
# - $a0 : Row that the paddle lives in (y-value)
# - $a1 : Colour of the paddle

# Brick initialization (drawing) function
draw_bricks:
    # Store current return address in stack
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Define starting positions
    lw $t0, ADDR_DSPL       # Start by loading in display address
    li $t1, 0               # Initialize row counter
    li $t7, 7               # Number of rows of bricks
    
    # Calculate starting position
    li $t2, 128             # Row width
    lw $t3, BORDER_SIDE_WIDTH
    lw $t4, BORDER_TOP_HEIGHT
    addi $t4, $t4, 2        # Add small gap after border
    
    # Calculate Y offset
    mult $t2, $t4
    mflo $t5                # Y offset = row_width * (border_height + gap)
    add $t0, $t0, $t5       # Add Y offset to starting position
    
    # Calculate X offset
    li $t5, 4               
    mult $t3, $t5           
    mflo $t6
    add $t0, $t0, $t6       # Add X offset to starting position
    
    draw_brick_loop:
        beq $t1, $t7, draw_brick_loop_end
        
        # Save registers
        addi $sp, $sp, -12
        sw $t0, 0($sp)
        sw $t1, 4($sp)
        sw $t7, 8($sp)
        
        # Draw brick
        add $a0, $zero, $t0         # Starting location
        addi $a1, $zero, 28         # Width of brick
        addi $a2, $zero, 1          # Height of brick
        lw $a3, BRICK_COLOURS       # Color of brick
        
        jal draw_rect
        
        # Restore registers
        lw $t0, 0($sp)
        lw $t1, 4($sp)
        lw $t7, 8($sp)
        addi $sp, $sp, 12
        
        # Move to next row
        addi $t0, $t0, 128      # Next row position
        addi $t1, $t1, 1        # Increment row counter
        
        j draw_brick_loop
    
    draw_brick_loop_end:
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra

# Ball drawing function
# No arguments!
draw_ball:
    lw $t0, BALL_X
    lw $t1, BALL_Y
    lw $t2, PLAYER_COLOUR
    lw $t5, ADDR_DSPL
    
    # Define values
    addi $t3, $zero, 128        # Saving 128 in a register for easy computation
    mult $t1, $t3               # Multiplying Y-Position by length of row
    mflo $t4
    add $t5, $t5, $t4           # Add product to $t5
    add $t5, $t5, $t0           # Add X-Position to current position
    
    # Draw the ball
    sw $t2, 0($t5)
    
    jr $ra

# The rectangle drawing function
#       This is the same code as in the handout starter code!
# Takes in the following:
# - $a0 : Starting location for drawing the rectangle
# - $a1 : The width of the rectangle
# - $a2 : The height of the rectangle
# - #a3 : The colour of the rectangle
draw_rect:
    add $t0, $zero, $a0		# Put drawing location into $t0
    add $t1, $zero, $a1		# Put the width into $t2
    add $t2, $zero, $a2		# Put the height into $t1
    add $t3, $zero, $a3		# Put the colour into $t3

    # Move down to next row if the line is done drawing
    outer_loop:
        beq $t2, $zero, end_outer_loop	# if the height variable is zero, then jump to the end.
    
    # Draw a horizontal line
    inner_loop:
        beq $t1, $zero, end_inner_loop	# if the width variable is zero, jump to the end of the inner loop
        sw $t3, 0($t0)			# draw a pixel at the current location.
        addi $t0, $t0, 4		# move the current drawing location to the right.
        addi $t1, $t1, -1		# decrement the width variable
        j inner_loop			# repeat the inner loop

    end_inner_loop:
        addi $t2, $t2, -1		# decrement the height variable
        add $t1, $zero, $a1		# reset the width variable to $a1
        # reset the current drawing location to the first pixel of the next line.
        addi $t0, $t0, 128		# move $t0 to the next line
        sll $t4, $t1, 2			# convert $t2 into bytes
        sub $t0, $t0, $t4		# move $t0 to the first pixel to draw in this line.
        j outer_loop			# jump to the beginning of the outer loop
    
    end_outer_loop:			# the end of the rectangle drawing
        jr $ra              # return to the calling program

# =============================================================================
#                               RESTART FUNCTION
# =============================================================================

restart_game:
    # Reset score
    la $t1, SCORE
    sw $zero, 0($t1)    # Set score back to 0
    
    # Reset game speed to initial value
    la $t1, GAME_SPEED
    li $t0, 80          # Initial speed value
    sw $t0, 0($t1)
    
    # Reset paddle position
    li $t0, 52
    la $t1, PADDLE_ONE_LEFT
    sw $t0, 0($t1)
    li $t0, 76
    la $t1, PADDLE_ONE_RIGHT
    sw $t0, 0($t1)
    li $t0, 30
    la $t1, PADDLE_ONE
    sw $t0, 0($t1)
    # Reset ball position
    li $t0, 60
    la $t1, BALL_X
    sw $t0, 0($t1)
    li $t0, 28
    la $t1, BALL_Y
    sw $t0, 0($t1)
    # Reset ball direction
    li $t0, 4
    la $t1, VEC_X
    sw $t0, 0($t1)
    li $t0, 1
    la $t1, VEC_Y
    sw $t0, 0($t1)
    # Redraw everything
    jal draw_scene
    j game_loop



# Function to draw Game Over display
draw_game_over_screen:
    # Store return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Get display address
    lw $t0, ADDR_DSPL
    la $t1, GAMEOVER_IMAGE
    
    # Initialize counters
    li $t2, 0          # pixel counter
    li $t3, 1024       # total pixels (32x32)
    
draw_image_loop:
    beq $t2, $t3, draw_image_done
    
    # Load color from image data
    lw $t4, 0($t1)
    
    # Store color to display
    sw $t4, 0($t0)
    
    # Update pointers and counter
    addi $t0, $t0, 4
    addi $t1, $t1, 4
    addi $t2, $t2, 1
    
    j draw_image_loop

draw_image_done:
    # Restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jal draw_score

wait_restart:
    lw $t0, ADDR_KBRD
    lw $t8, 0($t0)
    beq $t8, 1, check_restart_key
    j wait_restart

check_restart_key:
    lw $a0, 4($t0)
    beq $a0, 114, restart_game   # 'r' key to restart
    j wait_restart

# =============================================================================
#                               INPUT FUNCTIONS
# =============================================================================

# Pause the game
respond_to_p:
	lw $t0, ADDR_KBRD		# Load in the keyboard's address
	lw $t9, 0($t0)		
	beq $t9, 1, pause_input		
	j no_pause_input	
	
	pause_input:
	lw $t9, 4($t0)			
	beq $t9, 112, unpause	
	
	no_pause_input:
	b respond_to_p
	
	unpause:
	b game_loop

# Function to quit the game upon pressing q
respond_to_q:
    j exit

# Function that updates PADDLE_ONE to shift to the left
respond_to_a:
    # Store current return address in stack
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # 1. Paint over the paddle in the background colour
    lw $a0, PADDLE_ONE
    lw $a1, BACKGROUND_COLOUR
    
    jal draw_paddle_one
    
    # 2. Update variables for position of paddle
    lw $t0, PADDLE_ONE_LEFT         # Load paddle one's left pixel value
    lw $t2, PADDLE_ONE_RIGHT        # Load paddle one's right pixel value
    
    la $t5, PADDLE_ONE_LEFT
    addi $t1, $t0, -4               # Move it left
    
    la $t6, PADDLE_ONE_RIGHT
    addi $t3, $t2, -4               # Move it left
    
    # 2a. Check if we're touching the left wall
    beq $t1, 4, redraw_paddle_one_left     # Quit if we're touching the left wall
    
    sw $t1, 0($t5)                  # Update the variable
    sw $t3, 0($t6)                  # Update the variable
    
    # 3. Redraw the new paddle in the new position
    redraw_paddle_one_left:
        lw $a0, PADDLE_ONE
        lw $a1, PLAYER_COLOUR
        
        jal draw_paddle_one
    
    # Pop address on stack and return
    paddle_one_done_left:
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        
        j input_end                  # Return to game loop instead of jr $ra

# Function that updates PADDLE_ONE to shift to the RIGHT
respond_to_d:
    # Store current return address in stack
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # 1. Paint over the paddle in the background colour
    lw $a0, PADDLE_ONE
    lw $a1, BACKGROUND_COLOUR
    
    jal draw_paddle_one
    
    # 2. Update variables for position of paddle
    lw $t0, PADDLE_ONE_LEFT         # Load paddle one's left pixel value
    lw $t2, PADDLE_ONE_RIGHT        # Load paddle one's right pixel value
    
    la $t5, PADDLE_ONE_LEFT
    la $t6, PADDLE_ONE_RIGHT
    
    addi $t1, $t0, 4                # Move it right
    addi $t3, $t2, 4                # Move it right
    
    # 2b. Check if we're touching the right wall
    beq $t3, 124, redraw_paddle_one_right     # Quit if we're touching the right wall
    
    sw $t1, 0($t5)                  # Update the variable
    sw $t3, 0($t6)                  # Update the variable
    
    # 3. Redraw the new paddle in the new position
    redraw_paddle_one_right:
        lw $a0, PADDLE_ONE
        lw $a1, PLAYER_COLOUR
    
        jal draw_paddle_one
    
    # Pop address on stack and return
    paddle_one_done_right:
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        
        j input_end                  # Return to game loop instead of jr $ra

# =============================================================================
#                                    MOVEMENT
# =============================================================================

# Function to redraw the ball at (BALL_X + VEC_X, BALL_Y + VEC_Y)
move_ball:
    # Store current return address in stack
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # 1. Get current location of the ball and store it in $t4
    lw $t0, ADDR_DSPL
    lw $t1, BALL_X
    lw $t2, BALL_Y
    
    li $t3, 128
    
    mult $t3, $t2               # Multiply 128 * BALL_Y
    mflo $t4
    add $t4, $t4, $t0           # Add product to current location
    add $t4, $t4, $t1           # Add BALL_X to current location
    
    # 2. Get new X and Y of the ball
    lw $t5, VEC_X
    lw $t6, VEC_Y
    
    add $t7, $t1, $t5           # Add VEC_X to BALL_X
    add $t8, $t2, $t6           # Add VEC_Y to BALL_Y
    
    # 3. Erase the ball at previous location
    lw $t3, BACKGROUND_COLOUR
    sw $t3, 0($t4)              # Erase the ball at old location
    
    # 4. Set BALL_X and BALL_Y variables to new coordinates 
    la $t1, BALL_X
    la $t2, BALL_Y
    sw $t7, 0($t1)              # Set BALL_X to BALL_X + VEC_X
    sw $t8, 0($t2)              # Set BALL_Y to BALL_Y + VEC_Y
    jal draw_ball
    
    # Pop address on stack and return
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra

# =============================================================================
#                      GAMEPLAY EVENTS (BRICKS, LIVES, etc.)
# =============================================================================
    
# Function to process a brick being hit
# Takes in the following:
# - $a0 : position of the pixel within the brick being hit
hit_brick:
    # Store return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # 1. Increase SCORE by 1
    la $t0, SCORE
    lw $t1, 0($t0)
    addi $t1, $t1, 1
    sw $t1, 0($t0)
    
    # Check if score is 5 to increase speed
    beq $t1, 5, increase_speed
    j continue_hit_brick

increase_speed:
    # Reduce GAME_SPEED by 25% (multiply by 0.75)
    la $t0, GAME_SPEED
    lw $t1, 0($t0)
    # Multiply by 3/4 to get 75% of original speed
    li $t2, 3              # Load constant 3 into register
    mult $t1, $t2          # Multiply by 3 (both operands must be registers)
    mflo $t1
    srl $t1, $t1, 2       # Divide by 4
    sw $t1, 0($t0)
    j continue_hit_brick
    
continue_hit_brick:
    # 2. Get position and background color
    add $t1, $zero, $a0         # Store location in $t1
    lw $t3, BACKGROUND_COLOUR
    
    # 3. Check actual starting pixel of the brick
    addi $t5, $zero, 4
    div $t1, $t5
    mflo $t4
    andi $t6, $t4, 1            # Check if the starting pixel is even
    bnez $t6, odd
    j erase_brick               # If it's even, proceed to erase
    
    odd:
        addi $t4, $t4, -1       # Move starting point to the left by one if position is odd
        mult $t4, $t5
        mflo $t1
    
    # 4. Erase the brick (replace with background color)
    erase_brick:
        sw $t3, 0($t1)          # Erase first half of brick
        sw $t3, 4($t1)          # Erase second half of brick
    
    hit_brick_end:
        jr $ra

# Function called when ball hits bottom
die: 
    # Store current return address in stack
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    j exit        # Go directly to game over

# Function to clean up all player graphics (paddles and ball)
erase_player:
    # Store current return address in stack
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $t0, ADDR_DSPL
    lw $t1, BACKGROUND_COLOUR
    lw $t2, BORDER_TOP_HEIGHT
    lw $t3, BORDER_SIDE_WIDTH
    
    addi $t2, $t2, 10            # 3 rows for the gap + 7 rows of bricks
    
    li $t4, 128                  # Storing 128 for computational use
    mult $t4, $t2
    mflo $t5
    
    add $t0, $t0, $t5            # Adding product to position
    lw $t4, BORDER_SIDE_WIDTH_UNITS
    add $t0, $t0, $t4
    
    li $t6, 32
    sub $t7, $t6, $t2 
    sub $t8, $t6, $t3
    sub $t8, $t8, $t3
    
    add $a0, $zero, $t0
    add $a1, $zero, $t8
    add $a2, $zero, $t7 
    add $a3, $zero, $t1
    jal draw_rect
    
    # Pop address on stack and return
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra
     
# =============================================================================
#                              COLLISION CHECKING
# =============================================================================

# Combined collision detection function
# Takes direction as parameter:
# $a0 = 0 (top), 1 (right), 2 (bottom), 3 (left)
check_collision:
    # Store current return address in stack
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # 1. Get current ball location
    lw $t0, BALL_X
    lw $t1, BALL_Y
    
    # Adjust position based on direction
    beq $a0, 0, check_top
    beq $a0, 1, check_right
    beq $a0, 2, check_bottom
    beq $a0, 3, check_left
    j collision_end
    
    check_top:
        addi $t1, $t1, -1       # Check above
        j compute_location
    check_right:
        addi $t0, $t0, 4        # Check right
        j compute_location
    check_bottom:
        addi $t1, $t1, 1        # Check below
        beq $t1, 32, die        # Check if ball entered void
        j compute_location
    check_left:
        addi $t0, $t0, -4       # Check left
        
    compute_location:
        # 2. Compute collision check location
        lw $t2, ADDR_DSPL
        li $t3, 128
        mult $t3, $t1
        mflo $t4
        add $t4, $t4, $t2
        add $t4, $t4, $t0
    
    # 3. Check pixel color at location
    lw $t5, 0($t4)              # Color at check location
    lw $t3, BACKGROUND_COLOUR
    lw $t7, BORDER_COLOUR
    lw $t8, PLAYER_COLOUR
    
    beq $t5, $t8, handle_bounce # Paddle collision
    beq $t5, $t7, handle_bounce # Border collision
    beq $t5, $t3, collision_end # No collision (background)
    
    # If we get here, it's a brick collision
    handle_brick:
        beq $a0, 0, flip_y_break    # Top/Bottom = flip Y and break
        beq $a0, 2, flip_y_break
        j flip_x_break              # Left/Right = flip X and break
    
    # Handle bounce without breaking (for paddle and borders)
    handle_bounce:
        beq $a0, 0, flip_y_bounce   # Top/Bottom = flip Y only
        beq $a0, 2, flip_y_bounce
        j flip_x_bounce             # Left/Right = flip X only
        
    flip_y_bounce:
        la $t0, VEC_Y
        lw $t1, VEC_Y
        sub $t1, $zero, $t1     # Flip Y direction
        sw $t1, 0($t0)
        j collision_end
        
    flip_x_bounce:
        la $t0, VEC_X
        lw $t1, VEC_X
        sub $t1, $zero, $t1     # Flip X direction
        sw $t1, 0($t0)
        j collision_end
        
    flip_y_break:
        la $t0, VEC_Y
        lw $t1, VEC_Y
        sub $t1, $zero, $t1     # Flip Y direction
        sw $t1, 0($t0)
        add $a0, $zero, $t4     # Pass brick position
        jal hit_brick
        j collision_end
        
    flip_x_break:
        la $t0, VEC_X
        lw $t1, VEC_X
        sub $t1, $zero, $t1     # Flip X direction
        sw $t1, 0($t0)
        add $a0, $zero, $t4     # Pass brick position
        jal hit_brick
        
    collision_end:
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
# =============================================================================
#                                   EXIT
# =============================================================================

# Game Over and Exit
exit:
    jal draw_game_over_screen
    
    # Print final score
    jal draw_score

    # Terminate the program gracefully
    li $v0, 10
    syscall

# ==================================================
# draw_score
# Displays the current score in the console output.
# Writes "SCORE: X", where X is the current score.
# Only supports single-digit scores (0–9).
# ==================================================
draw_score:
    # Print the label "SCORE: "
    li $v0, 4
    la $a0, SCORE_LABEL
    syscall

    # Load score value from memory
    la $t0, SCORE
    lw $t1, 0($t0)

    # Convert score to ASCII character ('0' = 48)
    li $t2, 48
    add $a0, $t1, $t2

    # Print single digit score as character
    li $v0, 11
    syscall

    # Print newline
    li $v0, 4
    la $a0, NEWLINE
    syscall

    jr $ra