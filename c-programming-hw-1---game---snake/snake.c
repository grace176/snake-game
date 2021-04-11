/**********************************************************
 * file name   : snake.c                                  *
 * author      : YOU...replace this with your name        *
 * description : C program to implement the game snake    *
 *               This code will call your trap wrappers   *
 *               (located in lc4_stdio.asm)               *
 **********************************************************
*
*/

#include "lc4_stdio.h"


/*
 * ############################ DEFINES ############################
 */


/* Definitions for direction constants */

// Directions
#define UP    0             // We will use these constants to represent direcions with integers
#define DOWN  1
#define LEFT  2
#define RIGHT 3

// Game constants
#define MAX_LENGTH 25       // The maximum length of the snake
#define MAX_BOMBS 5         // The maximum number of bombs that should ever be on the screen

// Constants for all of the objects in the game
#define SNAKE 4
#define FRUIT 3
#define BOMB  2
#define WALL  1
#define EMPTY 0

// Possible game states
#define GAME_PLAYING 0
#define GAME_WON     1
#define GAME_LOST    2


/* LC4 system constants */

// Constants for controlling the timer
#define MAX_TIMER_SPEED 150             // The initial (slowest) value for the timer
#define TIMER_DECREMENT 30              // Each time the timer changes, it decreases by this much
#define MIN_TIMER 35                    // The fastest the timer should ever be set to

// Video constants
#define INDEX_SIZE 8                    // The size of each square on the screen (in pixels on the LC4)
#define ROWS    (124 / INDEX_SIZE)      // How many rows and columns of cells we will have in the game
#define COLUMNS (128 / INDEX_SIZE)


/* TYPE DEFINITIONS */

/*
 * Tuple type : This struct keeps track of an x and y position for an item in the game.
 * We will be using this to keep track of the snake, as well as items on the screen.
 *
 * For our game, the field 'x' will range from 0 to COLUMNS, and 'y' will range from 0 to ROWS.
 * Note that these x and y do not correspond to the exact pixel location on the screen.
 */
typedef struct tuple_t {
    int x;      // column
    int y;      // row
} Tuple;


/*
 * GLOBAL VARIABLES and DATA STRUCTURES
 */

Tuple snake[MAX_LENGTH];    // This array will represent the segments of our snake. Index 0 is the head
int snake_length;           // The current length of the snake. Its maximum is MAX_LENGTH
int snake_direction;        // The direction the snake is moving (with respect to the head)

Tuple bomb[MAX_BOMBS];      // An array of items, representing the locations of the bombs
Tuple fruit;                // The current location of the fruit
int bombs_count;            // How many bombs are on the screen (initially, 0)

int timer = MAX_TIMER_SPEED;    // In milliseconds, the current timer. This gets faster by TIMER_DECREMENT,
                                // every time a new bomb appears on the screen. Its minimum value is MIN_TIMER.


/* ############################ UTILITY ROUTINES ############################ */

/**
 * printnum: Print an integer to the ASCII display.
 *
 * This is a useful utility function for printing a decimal number to the LC4's
 * ASCII display. You don't need to use this in this assignment, but it may be very
 * helpful for debugging! Feel free to use this as you complete the homework.
 *
 * You don't have to modify these functions.
 */
void printnum (int n) {
  int abs_n;
  char str[10], *ptr;

  // Corner case (n == 0)
  if (n == 0) {
    lc4_puts ((lc4uint*)"0");
    return;
  }

  abs_n = (n < 0) ? -n : n;

  // Corner case (n == -32768) no corresponding +ve value
  if (abs_n < 0) {
    lc4_puts ((lc4uint*)"-32768");
    return;
  }

  ptr = str + 10; // beyond last character in string

  *(--ptr) = 0; // null termination

  while (abs_n) {
    *(--ptr) = (abs_n % 10) + 48; // generate ascii code for digit
    abs_n /= 10;
  }

  // Handle -ve numbers by adding - sign
  if (n < 0) *(--ptr) = '-';

  lc4_puts((lc4uint*)ptr);
}

/**
 * endl: Print a newline character.
 */
void endl () {
  lc4_puts((lc4uint*)"\n");
}

/**
 * rand16: Generates a random 16 bit number and returns a value between 0 and 127
 */
int rand16() {
    int lfsr;

    // Advance the lfsr seven times
    lfsr = lc4_lfsr();
    lfsr = lc4_lfsr();
    lfsr = lc4_lfsr();
    lfsr = lc4_lfsr();
    lfsr = lc4_lfsr();
    lfsr = lc4_lfsr();
    lfsr = lc4_lfsr();

    // return the last 7 bits
    return (lfsr & 0x7F);
}


/* ############################ SPRITES ############################ */

/**
 * These sprites can be used later on for extra credit. The sprites for 6
 * through 9 have been left blank. If you choose to do the extra credit,
 * complete sprites for 6-9 on your own. Use the examples provided as a guide!
 * You can skip to the next section for now.
 */

// Number 0
lc4uint zero [] = {
  0xFF,
  0xC3,
  0xC3,
  0xC3,
  0xC3,
  0xC3,
  0xC3,
  0xFF,
};

// Number 1
lc4uint one [] = {
  0x18,
  0x18,
  0x18,
  0x18,
  0x18,
  0x18,
  0x18,
  0x18,
};

// Number 2
lc4uint two [] = {
  0xFF,
  0xFF,
  0x07,
  0xFF,
  0xFF,
  0xE0,
  0xFF,
  0xFF,
};

// Number 3
lc4uint three [] = {
  0xFF,
  0xFF,
  0x07,
  0xFF,
  0xFF,
  0x07,
  0xFF,
  0xFF,
};

// Number 4
lc4uint four [] = {
  0xC3,
  0xC3,
  0xC3,
  0xFF,
  0x03,
  0x03,
  0x03,
  0x03,
};

// Number 5
lc4uint five [] = {
  0xFF,
  0xFF,
  0xE0,
  0xFF,
  0xFF,
  0x07,
  0xFF,
  0xFF,
};

// TODO: complete sprites for six, seven, eight, and nine

// Number 6
lc4uint six [] = {
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
};

// Number 7
lc4uint seven [] = {
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
};

// Number 8
lc4uint eight [] = {
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
};

// Number 9
lc4uint nine [] = {
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
};


/* ############################ INITIALIZATION ############################ */

/**
 * init_snake(): Reset our snake to its initial state
 * - no inputs or outputs.
 *
 * Initially, the length of the snake should be 1. The only segment of the snake
 * we will have is the head (snake[0]). You can set the initial location of the
 * head to x=10, y=10, and the initial direction to RIGHT.
 */
void init_snake() {
    int i; 
    int j;
    for (i = 0; i < COLUMNS; i++) {
        snake[i].x = -1;
    }
    for (j = 0; j < ROWS; j++) {
        snake[j].y = -1;
    }
    snake_length = 1; 
    snake[0].x = 10; 
    snake[0].y = 10;
    snake_direction = 3;
}

/**
 * reset_bombs(): Reset the state of the bombs array.
 * - no inputs or outputs.
 *
 * Initially, there should be no bombs on the screen. Don't worry about setting the
 * initial location of the fruit; you will do this in a separate function.
 */
void reset_bombs() {
    int i; 
    int j; 
    for (i = 0; i < COLUMNS; i++) {
        bomb[i].x = -1;
    }
    for (j = 0; j < ROWS; j++) {
        bomb[j].y = -1;
    }
    bombs_count = 0;
}


/* ############################ SNAKE CONTROL FUNCTIONS ############################ */

/**
 * turn_snake(): Change the direction of the snake
 * - INPUT: new_direction - the direction to set the head to
 *
 * This function will take in a direction (UP/DOWN/LEFT/RIGHT), and change the direction of the
 * snake, if that is allowed. The rule for turning is that the snake can only turn 90 degrees in
 * one turn (for example, if you're moving to the left, you can't immediately go right; you would
 * have to go up or down first, then turn right on the next clock tick).
 *
 * If the new direction isn't allowed, this function should do nothing.
 */
void turn_snake(int new_direction) {
    if (snake_direction = 2 && new_direction == 0) {
        snake_direction = 0;
    }
    if (snake_direction = 3 && new_direction == 0) {
        snake_direction = 0;
    }
    if (snake_direction = 2 && new_direction == 1) {
        snake_direction = 1;       
    }
    if (snake_direction = 3 && new_direction == 1) {
        snake_direction = 1;       
    }
    if (snake_direction = 0 && new_direction == 2) {
        snake_direction = 2;       
    }
    if (snake_direction = 1 && new_direction == 2) {
        snake_direction = 2;       
    }
    if (snake_direction = 0 && new_direction == 3) {
        snake_direction = 3;       
    }
    if (snake_direction = 1 && new_direction == 3) {
        snake_direction = 3;       
    }    
}

/**
 * grow_snake(): Increase the size of the snake.
 * - no inputs or outputs.
 *
 * This function will spawn a new segment of the snake after the tail.
 * HINT: use the 'snake_length' global.
 *
 * You don't need to check if the snake is at its maximum size. You can set the
 * position of the new segment to be equal to that of the previous tail; this will
 * be fixed by the movement of the snake.
 */
void grow_snake() {
    snake_length = snake_length + 1; 
    snake[snake_length + 1].x = snake[snake_length].x;
    snake[snake_length + 1].y = snake[snake_length].y; 
}

/**
 * move_snake(): Update the position of the entire snake.
 * - RETURNS: return 1 if the snake moved successfully.
 *            return 0 if the snake would have moved out of bounds.
 *
 * In this function, you will update the position of every segment of the snake. Note that
 * you need to guarantee the snake would not move out of bounds (use the ROWS and COLUMNS 
 * defines to help with this). Return 0 if the snake would have moved out of bounds. Otherwise,
 * update the snake and return 1.
 *
 * HINT: To move the snake, we are effectively setting the position of each snake[i]
 * to that of snake[i-1]. You will need to handle the head as a special case.
 */
int move_snake() {
    int i;
    if (snake_direction == 0) {
        snake[0].x = snake[0].x;
        snake[0].y = snake[0].y - 1;
        for (i = 1; i <= snake_length; i++) {
            snake[i].x = snake[i].x;
            snake[i].y = snake[i - 1].y;
        }
    }
    if (snake_direction == 1) {
        snake[0].x = snake[0].x;
        snake[0].y = snake[0].y + 1;
        for (i = 1; i <= snake_length; i++) {
            snake[i].x = snake[i].x;
            snake[i].y = snake[i - 1].y;
        }
    }
    if (snake_direction == 2) {
        snake[0].x = snake[0].x - 1;
        snake[0].y = snake[0].y;
        for (i = 1; i <= snake_length; i++) {
            snake[i].x = snake[i - 1].x;
            snake[i].y = snake[i].y;
        }
    }
    if (snake_direction == 3) {
        snake[0].x = snake[0].x + 1;
        snake[0].y = snake[0].y;
        for (i = 1; i <= snake_length; i++) {
            snake[i].x = snake[i - 1].x;
            snake[i].y = snake[i].y;
        }
    }   
    if (snake[0].x > COLUMNS || snake[snake_length].x > COLUMNS) {
        return 0;
    }
    if (snake[0].y > ROWS || snake[snake_length].y > ROWS) {
        return 0;
    }
    if (snake[0].x < 0 || snake[snake_length].x < 0) {
        return 0;
    }
    if (snake[0].y < 0|| snake[snake_length].y < 0) {
        return 0;
    }    
    return 1; 
}

/* ############################ ITEM CONTROL FUNCTIONS ############################ */

/**
 * spawn_fruit(): Spawn the fruit at a random location on the screen.
 *
 * This function will reset the location of the fruit to a new, random location.
 * HINT: You can use rand16() to generate random bits with the LC4's LFSR. Think about
 *       how you can use modulo (%) to keep the values in range.
 *
 * You should ensure that you don't spawn the fruit at a location where a bomb
 * already exists. This function should not return until it finds a safe place to
 * put the new fruit.
 */
void spawn_fruit() {
    fruit.x = rand16() % COLUMNS; 
    fruit.y = rand16() % ROWS;
}

/**
 * spawn_bomb(): Spawn a new bomb on the screen.
 *
 * Similarly to the previous function, this function will spawn a new bomb
 * at a random location. Again, make sure this location does not already contain
 * another bomb, or the fruit.
 *
 * Note: unlike spawn_fruit, this function spawns a NEW bomb (since bomb[i] is an array).
 * Remember to use the global 'bombs_count' to keep track of which index we are at.
 */
void spawn_bomb() {
    int i;
    for (i = 0; i < MAX_BOMBS; i++) {
        bomb[i].x = rand16() % COLUMNS; 
        bomb[i].y = rand16() % ROWS;
        bombs_count++;
     }
}

/* ############################ COLLISION DETECTORS ############################ */

/**
 * check_bomb_collision():
 * - RETURNS: return BOMB if the snake has hit a bomb, or EMPTY otherwise.
 *
 * This function will be called after the snake has moved, to see if we hit a bomb.
 * Return BOMB if the snake has hit one, or EMPTY otherwise.
 */
int check_bomb_collision() {
    int i;
    for (i = 0; i <= bombs_count; i++) {
        if (bomb[i].x == snake[0].x && bomb[i].y == snake[0].y) {
            return BOMB;
        }
    }
    return EMPTY;
}


/**
 * check_fruit_collision():
 * - RETURNS: return FRUIT if the snake has eaten the fruit, or EMPTY otherwise.
 *
 * Very similar to the above function. Return FRUIT if the snake has just hit the fruit,
 * or EMPTY otherwise.
 */
int check_fruit_collision() {
    if (fruit.x == snake[0].x && fruit.y == snake[0].y) {
        return FRUIT;
    }
    return EMPTY;
}


/**
 * check_fruit_collision():
 * - RETURNS: return SNAKE if the snake has collided with itself. Return EMPTY otherwise.
 *
 * Finally, we need to make sure the snake hasn't run into itself. To do this, check if the
 * head (snake[0]) has the same position as any of the other segments. If so, return SNAKE,
 * otherwise return EMPTY.
 */
int check_self_collision() {
    int i; 
    for (i = 0; i <= MAX_LENGTH; i++) {
        if (snake[i].x == snake[0].x && snake[i].y == snake[0].y) {
            return SNAKE;
        }
    }
    return EMPTY;
}

/**
 * handle_collisions():
 * - RETURNS: the type of the object (SNAKE/BOMB/FRUIT) the snake has collided with, if any.
 *            Returns EMPTY if the snake did not hit anything.
 *
 * Now it's time to put all of your previous functions together. This function should
 * call all of the above three functions, and return whether the snake ran into anything.
 */
int handle_collisions() {
    if (check_self_collision() == 4) {
        return SNAKE; 
    }
    if (check_fruit_collision() == 3) {
        return FRUIT;
    }
    if (check_bomb_collision() == 2) {
        return BOMB;
    }
    return EMPTY;
}


/* ############################ GAME STATE FUNCTION ############################ */

/**
 * update_game_state():
 * - RETURNS: the new state (GAME_PLAYING/GAME_WON/GAME_LOST) of the game after this clock tick
 *
 * This function will bring together many of the functions you've written so far, to simulate
 * updating the game. You should do three main tasks:
 *  1. Move the snake with move_snake(). If the snake went out of bounds, the game is lost.
 *  2. Check for collisions with handle_collisions(). If the snake hit a bomb or itself,
 *     the game is lost. If the snake hit a fruit, you should spawn a new fruit, grow the snake,
 *     and keep playing.
 *  3. Check for winning conditions. If the snake's length ever equals MAX_LENGTH, the game is won.
 * You should return GAME_WON, GAME_LOST, or GAME_PLAYING if the player has won, lost, or is still in
 * the middle of the game.
 *
 * In addition to the above checks, you should also do the following every time the snake
 * grows to a length that is divisible by 5:
 *  - Spawn a new bomb
 *  - Decrease the 'timer' global by TIMER_DECREMENT. However, don't decrease it below MIN_TIMER.
 *  - Print a message to the LC4 display (with lc4_puts)
 * HINT: use modulo (snake_length % 5) to see if the snake's new length is divisible by 5.
 */
int update_game_state() {
    int t = lc4_getc_timer(timer); 
    move_snake();
    if (snake[snake_length].x > COLUMNS || snake[snake_length].y > ROWS ) {
        return GAME_LOST;
    }
    handle_collisions();
    if (snake_length = MAX_LENGTH) {
        return GAME_WON;
    }
    if (snake_length % 5 == 0) {
        spawn_bomb();
        handle_collisions();
        if (handle_collisions() == 2) {
            return GAME_LOST;
        }
        if (handle_collisions() == 4) {
            return GAME_LOST;
        }
        if (handle_collisions() == 3) {
            spawn_fruit();
            grow_snake();
            return GAME_PLAYING;
        } 
        if (snake_length % 5 == 0) {
            spawn_bomb();
            if (t - TIMER_DECREMENT > 0) {
                t -= TIMER_DECREMENT;   
            }
            timer = t; 
            lc4_puts ((lc4uint*)"Length multiple of 5!\n");
        }
    }   
    return GAME_PLAYING;
}


/* ############################ GRAPHICS ############################ */

/**
 * These two functions are utilities. You can use draw_pixel() below as a wrapper
 * for lc4_draw_rect(). You don't need to modify either function.
 */
int index_to_pixel(int index) {
    return index * INDEX_SIZE;
}

void draw_pixel(int row, int col, unsigned int color) {
    int x = index_to_pixel(col);
    int y = index_to_pixel(row);
    lc4_draw_rect(x, y, INDEX_SIZE, INDEX_SIZE, color);
}

/**
 * draw_snake(): Draw the snake to the screen.
 *
 * In this function, you will iterate through the snake[] array and draw the
 * entire snake to the screen. You can use the function draw_pixel() to help you
 * with this. The color of the snake should be GREEN.
 */
void draw_snake() {
    int i;
    int j;
    int row;
    int col; 
    for (i = 0; i < MAX_LENGTH; i++) {
        for (j = 0; j < MAX_LENGTH; j++) {
            row = index_to_pixel(bomb[j].y);
            col = index_to_pixel(bomb[i].x);
            draw_pixel(row, col, GREEN);
        }
    }          
}

/**
 * draw_bombs(): Draw all of the bombs to the screen.
 *
 * This function will draw all of the bombs to the screen. The color of the bombs
 * will be WHITE.
 */
void draw_bombs() {
    int i;
    int j;
    int col;
    int row;
    for (i = 0; i < MAX_BOMBS; i++) {
        for (j = 0; j < MAX_BOMBS; j++) {
            row = index_to_pixel(bomb[j].y);
            col = index_to_pixel(bomb[i].x);
            lc4_draw_rect(col, row, INDEX_SIZE, INDEX_SIZE, WHITE);
        }
    }   
}

/**
 * draw_fruit(): Draw the fruit to the screen.
 *
 * Finally, draw the fruit. The color of the fruit will be RED.
 */
void draw_fruit() {
    int col = index_to_pixel(fruit.x);
    int row = index_to_pixel(fruit.y);
    lc4_draw_rect(col, row, INDEX_SIZE, INDEX_SIZE, RED);  
}

/**
 * %%%%%% EXTRA CREDIT %%%%%%
 *
 * display_score(): Draw the current length of the snake on the screen.
 *
 * For extra credit, use the sprites above and the function lc4_draw_sprite
 * to display the length of the snake on the screen. You can place the score in
 * the top left corner of the screen; don't worry about it overlapping with
 * the rest of the game. The color of the sprites should be YELLOW.
 *
 * Make sure you complete the blank sprites (6-9) if you haven't already!
 */
void display_score() {
    //EXTRA CREDIT
    return;
}

/**
 * This function is a wrapper for all the graphics functions you've written above.
 * You don't need to modify this function.
 */
void redraw() {
    lc4_reset_vmem();

    // Draw the game board
    draw_snake();
    draw_bombs();
    draw_fruit();

    // Display the score, for extra credit.
    display_score();

    lc4_blt_vmem();
}


/*
 * ############################  MAIN PROGRAM  ############################
 */


/**
 * play_game(): A function to encapsulate a single game of SNAKE.
 *
 * This final function will bring together everything you've written, to create a full
 * game of snake. You should first initialize the state and reset all of the game's globals,
 * and then loop as long as the state is GAME_PLAYING.
 *
 * On each loop, you should wait for a keypress from the player, for 'timer' milliseconds. If
 * the player enters 'i', 'j', 'k', or 'l', turn the snake UP, LEFT, DOWN, or RIGHT, respectively.
 * Then, you should call update_game_state() to update the game, and redraw the screen.
 *
 * When the player wins or loses, print a message to the ASCII display, and return. Also, if the
 * player hits 'q' at any point, quit the game immediately (and return).
 *
 * Some skeleton code and comments have been provided to help you get started. Be sure
 * to add your own comments as well as you go along!
 *
 * HINT: The functions lc4_getc_timer() and lc4_puts() will be useful for this function.
 *       For examples of how these routines work, see the MAIN function below.
 */
void play_game() {
    // Locals (feel free to add your own!)
    int state = GAME_PLAYING;
    timer = MAX_TIMER_SPEED;

    // TODO: Initialize everything, and draw the screen...
    init_snake();
    spawn_bomb();
    spawn_fruit();
    redraw();
     
    // Loop, while the game is playing...
    while (state == GAME_PLAYING) {
        int key = 0;

        // TODO: get the next key
        key = lc4_getc_timer(timer);

        /* 1. Handle keypress cases... */
        if (key == 'i') {
            turn_snake(0);
        }
        if (key == 'k') {
            turn_snake(1);
        }
        if (key = 'j') {
            turn_snake(2);
        }
        if (key = 'l') {
            turn_snake(3);
        }
        /* 2. Update game state and redraw... */
        update_game_state();
        redraw();

        /* 3. Loop based on new state... */

    }
    if (state == GAME_LOST) {
        lc4_puts ((lc4uint*)"\nLOSER\n");
    }
    if (state == GAME_WON) {
        lc4_puts ((lc4uint*)"\nWINNER\n");
    }
    if (lc4_getc_timer(timer) == 'q') {
        init_snake();
        spawn_bomb();
        spawn_fruit();
        redraw();   
    }   
}



/* ############################################################ */


/**
 * The main function. You don'T need to modify this.
 */
int main() {
    int key = 0;
    lc4_puts ((lc4uint*)"Welcome to Snake!\n");
    lc4_puts ((lc4uint*)"Press 'r' to start\n");

    while (TRUE) {

        // Wait for the 'r' key to start
        key = lc4_getc_timer(100);
        if (key == 'q') {
            break;
        }

        // Start the game!
        else if (key == 'r') {
        	lc4_puts ((lc4uint*)"\nNew game!\n");
            lc4_puts ((lc4uint*)"Use i, j, k, l to move\n");
        	lc4_puts ((lc4uint*)"Eat food (red) to grow, and avoid bombs (white)\n");
            play_game();
            lc4_puts ((lc4uint*)"Press 'r' to play again, or 'q' to quit...\n");
        }
    }

    return 0;
}
