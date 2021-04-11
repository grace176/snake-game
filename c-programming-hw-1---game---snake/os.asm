;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  file name   : os.asm                                 ;
;  author      : 
;  description : LC4 Assembly program to serve as an OS ;
;                TRAPS will be implemented in this file ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;

;; TO-DO:
;; 1) Open up your last codio assignment (in a separate browswer window)
;; 2) In that window, open up your working os.asm file:
;;    -select everything in the file, and "copy" this content (Conrol-C) 
;; 3) Return to the current codio assignment, paste the content into this os.asm 
;;    -now you can use the os.asm from your last HW in this HW
;; 4) Save the updated os.asm file

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;   OS - TRAP VECTOR TABLE   ;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.OS
.CODE
.ADDR x8000
  ; TRAP vector table
  JMP TRAP_GETC           ; x00
  JMP TRAP_PUTC           ; x01
  JMP TRAP_GETS           ; x02
  JMP TRAP_PUTS           ; x03
  JMP TRAP_TIMER          ; x04
  JMP TRAP_GETC_TIMER     ; x05
  JMP TRAP_RESET_VMEM	  ; x06
  JMP TRAP_BLT_VMEM	      ; x07
  JMP TRAP_DRAW_PIXEL     ; x08
  JMP TRAP_DRAW_RECT      ; x09
  JMP TRAP_DRAW_SPRITE    ; x0A

  ;
  ; TO DO - add additional vectors as described in homework 
  ;
  JMP TRAP_LFSR_SET_SEED  ; x0B
  JMP TRAP_LFSR           ; x0C
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;   OS - MEMORY ADDRESSES & CONSTANTS   ;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;; these handy alias' will be used in the TRAPs that follow
  USER_CODE_ADDR .UCONST x0000	; start of USER code
  OS_CODE_ADDR 	 .UCONST x8000	; start of OS code

  OS_GLOBALS_ADDR .UCONST xA000	; start of OS global mem
  OS_STACK_ADDR   .UCONST xBFFF	; start of OS stack mem

  OS_KBSR_ADDR .UCONST xFE00  	; alias for keyboard status reg
  OS_KBDR_ADDR .UCONST xFE02  	; alias for keyboard data reg

  OS_ADSR_ADDR .UCONST xFE04  	; alias for display status register
  OS_ADDR_ADDR .UCONST xFE06  	; alias for display data register

  OS_TSR_ADDR .UCONST xFE08 	; alias for timer status register
  OS_TIR_ADDR .UCONST xFE0A 	; alias for timer interval register

  OS_VDCR_ADDR	.UCONST xFE0C	; video display control register
  OS_MCR_ADDR	.UCONST xFFEE	; machine control register
  OS_VIDEO_NUM_COLS .UCONST #128
  OS_VIDEO_NUM_ROWS .UCONST #124


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; OS DATA MEMORY RESERVATIONS ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.DATA
.ADDR xA000
OS_GLOBALS_MEM	.BLKW x1000
;;;  LFSR value used by lfsr code
LFSR .FILL 0x0001

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; OS VIDEO MEMORY RESERVATION ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.DATA
.ADDR xC000
OS_VIDEO_MEM .BLKW x3E00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;   OS & TRAP IMPLEMENTATIONS BEGIN HERE   ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.CODE
.ADDR x8200
.FALIGN
  ;; first job of OS is to return PennSim to x0000 & downgrade privledge
  CONST R7, #0   ; R7 = 0
  RTI            ; PC = R7 ; PSR[15]=0


;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_GETC   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Get a single character from keyboard
;;; Inputs           - none
;;; Outputs          - R0 = ASCII character from ASCII keyboard

.CODE
TRAP_GETC
    LC R0, OS_KBSR_ADDR  ; R0 = address of keyboard status reg
    LDR R0, R0, #0       ; R0 = value of keyboard status reg
    BRzp TRAP_GETC       ; if R0[15]=1, data is waiting!
                             ; else, loop and check again...

    ; reaching here, means data is waiting in keyboard data reg

    LC R0, OS_KBDR_ADDR  ; R0 = address of keyboard data reg
    LDR R0, R0, #0       ; R0 = value of keyboard data reg
    RTI                  ; PC = R7 ; PSR[15]=0


;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_PUTC   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Put a single character out to ASCII display
;;; Inputs           - R0 = ASCII character to write to ASCII display
;;; Outputs          - none

.CODE
TRAP_PUTC
  LC R1, OS_ADSR_ADDR 	; R1 = address of display status reg
  LDR R1, R1, #0    	; R1 = value of display status reg
  BRzp TRAP_PUTC    	; if R1[15]=1, display is ready to write!
		    	        ; else, loop and check again...

  ; reaching here, means console is ready to display next char

  LC R1, OS_ADDR_ADDR 	; R1 = address of display data reg
  STR R0, R1, #0    	; R1 = value of keyboard data reg (R0)
  RTI			        ; PC = R7 ; PSR[15]=0


;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_GETS   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Get a string of characters from the ASCII keyboard
;;; Inputs           - R0 = Address to place characters from keyboard
;;; Outputs          - R1 = Length of the string without the NULL

.CODE
TRAP_GETS

  ;;
  ;;
  ;;
  
  CONST R6, xFF
  HICONST R6, x7F
  CMP R0, R6           ; sets  NZP (R0 - R3)
  BRp CALLER_TRAP_GETS ; address out of (upper)bound then return caller else continue 
  
  CONST R6, x00
  HICONST R6, x20
  CMP R0, R6           ; sets  NZP (R0 - R3)
  BRnz CALLER_TRAP_GETS; address out of (lower)bound then return caller else continue 
  
WHILE_LOOP 
  LC R2, OS_KBSR_ADDR  ; R2 = address of keyboard status reg
  LDR R2, R2, #0       ; R2 = value of keyboard status reg
  BRzp WHILE_LOOP      ; if R2[15]=1, data is waiting else loop and check again

  ; reaching here, means data is waiting in keyboard data reg

  LC R2, OS_KBDR_ADDR  ; R2 = address of keyboard data reg
  LDR R2, R2, #0       ; R2 = value of keyboard data reg

  CMPI R2, x0D         ; sets  NZP (R2 - x0D)
  BRz NULL_STRING      ; if enter then null the string and return to caller  
  
  STR R2, R0, #0       ;  
  ADD R1, R1, #1       ; count the length of the string 
  ADD R0, R0, #1       ; add new data memory address 
  JMP TRAP_GETS        ; loop back 
  
NULL_STRING
  CONST R4, x00        ; constant for null
  STR R4, R0, #0       ; store this in data memory address in R0
 
  CALLER_TRAP_GETS
  RTI
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_PUTS   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Put a string of characters out to ASCII display
;;; Inputs           - R0 = Address for first character
;;; Outputs          - none

.CODE
TRAP_PUTS

  ;;
  ;;
  ;;
  
  CONST R6, xFF
  HICONST R6, x7F
  CMP R0, R6            ; sets NZP R0 - R6 
  BRp CALLER_TRAP_PUTS  ; address out of (upper)bound then return caller else continue 
  
  CONST R6, x00
  HICONST R6, x20
  CMP R0, R6            ; sets NZP R0 - R6
  BRn CALLER_TRAP_PUTS  ; address out of (lower)bound then return caller else continue 
  
LOOP 
  LDR R1, R0, #0        ; load the characters in R0 to R1
  CMPI R1, #0           ; compare R1 to null 
  BRz CALLER_TRAP_PUTS  ; if character is null, exit 

  LC R2, OS_ADSR_ADDR   ; Load into R2 the address of the status register for the ASCII display
  LDR R3, R2, #0        ; Load into R3 the actual status of the ASCII display status register 
  BRzp LOOP       ; If 1 is not in the MSB then loop back 
  
  ;; reaching here mean ready to display next character
  
  LC R2, OS_ADDR_ADDR   ; Load into R1 address of the data register of ASCII display 
  STR R1, R2, #0        ; store in R2 the content 
  ADD R0, R0, #1        ; get the data memory address of the next characracter   
  BRnzp TRAP_PUTS       ; loop back to the top 
  
  CALLER_TRAP_PUTS
  RTI

;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_TIMER   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function:
;;; Inputs           - R0 = time to wait in milliseconds
;;; Outputs          - none

.CODE
TRAP_TIMER
  LC R1, OS_TIR_ADDR 	; R1 = address of timer interval reg
  STR R0, R1, #0    	; Store R0 in timer interval register

COUNT
  LC R1, OS_TSR_ADDR  	; Save timer status register in R1
  LDR R1, R1, #0    	; Load the contents of TSR in R1
  BRzp COUNT    	    ; If R1[15]=1, timer has gone off!

  ; reaching this line means we've finished counting R0

  RTI       		; PC = R7 ; PSR[15]=0

;;;;;;;;;;;;;;;;;;;;;;;   TRAP_GETC_TIMER   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Get a single character from keyboard
;;; Inputs           - R0 = time to wait
;;; Outputs          - R0 = ASCII character from keyboard (or NULL)

.CODE
TRAP_GETC_TIMER

  ;;
  ;; 
  ;;  
  
  LC R1, OS_TIR_ADDR     ; R1 = address of timer interval reg
  STR R0, R1, #0         ; timer interval register 
  
GETC_TIMER_COUNT
  LC R2, OS_KBSR_ADDR  	 ; R2 = adddress of keyboard status 
  LDR R2, R2, #0    	 ; R2 = value of keyboard status    
  BRn KEY_FOUND          ; a key is found 
  
  LC R1, OS_TSR_ADDR     ; R1 = address of timer status 
  LDR R1, R1, #0         ; R1 = value of TSR 
  BRzp GETC_TIMER_COUNT  ; timer is not completed 

  CONST R0, #0           ; no key was pressed
  BRnzp CALLER_GETC_TIMER; if R0 = 0, return to caller 

KEY_FOUND
  LC R0, OS_KBDR_ADDR    ; R0 = address of keyboard data reg
  LDR R0, R0, #0         ; R0 = value of keyboard data reg
  BRnzp CALLER_GETC_TIMER; 
  
  CALLER_GETC_TIMER
  RTI                    ; PC = R7 ; PSR[15]=0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;; TRAP_RESET_VMEM ;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; In double-buffered video mode, resets the video display
;;; DO NOT MODIFY this trap, it's for future HWs
;;; Inputs - none
;;; Outputs - none
.CODE	
TRAP_RESET_VMEM
  LC R4, OS_VDCR_ADDR
  CONST R5, #1
  STR R5, R4, #0
  RTI


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; TRAP_BLT_VMEM ;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TRAP_BLT_VMEM - In double-buffered video mode, copies the contents
;;; of video memory to the video display.
;;; DO NOT MODIFY this trap, it's for future HWs
;;; Inputs - none
;;; Outputs - none
.CODE
TRAP_BLT_VMEM
  LC R4, OS_VDCR_ADDR
  CONST R5, #2
  STR R5, R4, #0
  RTI

;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_DRAW_PIXEL   ;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Draw point on video display
;;; Inputs           - R0 = row to draw on (y)
;;;                  - R1 = column to draw on (x)
;;;                  - R2 = color to draw with
;;; Outputs          - none

.CODE
TRAP_DRAW_PIXEL
  LEA R3, OS_VIDEO_MEM       ; R3=start address of video memory
  LC  R4, OS_VIDEO_NUM_COLS  ; R4=number of columns

  CMPIU R1, #0    	         ; Checks if x coord from input is > 0
  BRn END_PIXEL
  CMPIU R1, #127    	     ; Checks if x coord from input is < 127
  BRp END_PIXEL
  CMPIU R0, #0    	         ; Checks if y coord from input is > 0
  BRn END_PIXEL
  CMPIU R0, #123    	     ; Checks if y coord from input is < 123
  BRp END_PIXEL

  MUL R4, R0, R4      	     ; R4= (row * NUM_COLS)
  ADD R4, R4, R1      	     ; R4= (row * NUM_COLS) + col
  ADD R4, R4, R3      	     ; Add the offset to the start of video memory
  STR R2, R4, #0      	     ; Fill in the pixel with color from user (R2)

END_PIXEL
  RTI       		         ; PC = R7 ; PSR[15]=0
  

;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_DRAW_RECT   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Draw a rectangle out to the video display 
;;; Inputs    R0 = x coordinate of upper-left corner of the rectangle 
;;;           R1 = y coordinate of upper-left corner of the rectangle 
;;;           R2 = length of the rectangle (in number of pixels)
;;;           R3 - width of the side of the rectangle 
;;;           R4 = the color of the rectangle
;;; Outputs   None 

.CODE
TRAP_DRAW_RECT

	CMPI R2, #0
	BRnz CALLER_TRAP_DRAW_RECT
	CMPI R3, #0
	BRnz CALLER_TRAP_DRAW_RECT

	ADD R3, R3, R1
	LC R5 OS_VIDEO_NUM_ROWS
	CMP R3, R5
	BRnz TRAP_DRAW_RECT_1
	LC R3 OS_VIDEO_NUM_ROWS
    
TRAP_DRAW_RECT_1
	CMPI R1, #0
	BRzp TRAP_DRAW_RECT_2
	CONST R1, #0
    
TRAP_DRAW_RECT_2
	ADD R2, R2, R0
	LC R5 OS_VIDEO_NUM_COLS
	CMP R2, R5
	BRnz TRAP_DRAW_RECT_3
	LC R2 OS_VIDEO_NUM_COLS
    
TRAP_DRAW_RECT_3
	CMPI R0, #0
	BRzp TRAP_DRAW_RECT_4
	CONST R0, #0
    
TRAP_DRAW_RECT_4
	;; R1 - row
	;; R5 - col
	;; R6 - ptr to video memory
	
	JMP TRAP_DRAW_RECT_6

TRAP_DRAW_RECT_5
	;; Set up ptr in R6 using R5
	SLL R6, R1, #7		
	LEA R5, OS_VIDEO_MEM
	ADD R6, R6, R5
	ADD R6, R6, R0
	ADD R5, R0, #0		
	JMP TRAP_DRAW_RECT_8
    
TRAP_DRAW_RECT_7
	STR R4, R6, #0		; *ptr = color
	ADD R6, R6, #1		; increment ptr
	ADD R5, R5, #1		; increment col
    
TRAP_DRAW_RECT_8
	CMP R5, R2
	BRn TRAP_DRAW_RECT_7
	ADD R1, R1, #1 		; increment row
    
TRAP_DRAW_RECT_6
	CMP R1, R3
	BRn TRAP_DRAW_RECT_5
	
CALLER_TRAP_DRAW_RECT
	RTI
  


;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_DRAW_SPRITE   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Draw an 8x8 block of pixels on the video display 
;;; Inputs    - R0: starting col in video memory 
;;;           - R1: starting row in video memory 
;;;           - R2: color of the sprite 
;;;           - R3: starting address of an array of 8 
;;; Outputs   None 

.CODE
TRAP_DRAW_SPRITE
    LEA R6, OS_GLOBALS_MEM 
    STR R0, R6, #0 
    STR R1, R6, #1 
    STR R7, R6, #2 
	CONST R0, #0                   
	JMP TRAP_DRAW_SPRITE_2 

TRAP_DRAW_SPRITE_1 

	LEA R6, OS_GLOBALS_MEM 
	LDR R1, R6, #1                 ; load start_row 
	ADD R1, R1, R0                 ; temp = i + start_row 
	BRn TRAP_DRAW_SPRITE_3       
	LC R7 OS_VIDEO_NUM_ROWS 
	CMP R1, R7 
	BRzp CALLER_TRAP_DRAW_SPRITE      
	LDR R4, R3, #0                 
	CONST R7, 0xFF 
	AND R4, R4, R7                  
	LEA R6, OS_GLOBALS_MEM 
	LDR R5, R6, #0                 
	ADD R5, R5, #7                 ; col = start_col + 7 
	SLL R1, R1, #7                 ; temp = temp * 128 
	ADD R1, R1, R5                 ; temp = temp + col 
	LEA R7, OS_VIDEO_MEM 
	ADD R1, R1, R7                 

	LC R7, OS_VIDEO_NUM_COLS 

TRAP_DRAW_SPRITE_4 

	CMPI R5, #0 
	BRn TRAP_DRAW_SPRITE_5        
	CMP R5, R7 
	BRzp TRAP_DRAW_SPRITE_5        
	AND R6, R4, 0x01 
	BRz TRAP_DRAW_SPRITE_5         
	STR R2, R1, 0                  

TRAP_DRAW_SPRITE_5 
	
	ADD R5, R5, #-1                
	ADD R1, R1, #-1                
	SRL R4, R4, #1                 
	BRnp TRAP_DRAW_SPRITE_4 

TRAP_DRAW_SPRITE_3 
	ADD R0, R0, #1                 
	ADD R3, R3, #1                  
    
TRAP_DRAW_SPRITE_2 
	CMPI R0, #8 
	BRn TRAP_DRAW_SPRITE_1 

CALLER_TRAP_DRAW_SPRITE 
	LEA R6, OS_GLOBALS_MEM 
	LDR R7, R6, #2 
RTI
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_LFSR_SET_SEED   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Set a seed value in data memory for the other trap to use 
;;; Inputs    R0 = 16-bit number (the seed for the LFSR TRAP)
;;; Outputs   None

.CODE
TRAP_LFSR_SET_SEED

  ;;
  ;; 
  ;;
  
  LEA R1, LFSR                    ; R1 = xA000
  STR R0, R1, #0                  ; store the number passed in R0 in data memory 

  RTI                             ; PC = R7; PSR[15]=0

;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_LFSR   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: one-bit shift 
;;; Inputs    None 
;;; Outputs   R0 = pseudo-random number by one-bit shift 

.CODE
TRAP_LFSR

  ;;
  ;; 
  ;;
  
  LEA R1, LFSR                    ; R1 = xA000
  LDR R0, R1, #0                  ; store the number passed in R0 in data memory
  SLL R2, R0, #2                  ; MSB is bit 13
  XOR R3, R0, R2                  ; XOR bit 15 and 13  
  SLL R2, R0, #3                  ; MSB is bit 12
  XOR R3, R2, R3                  ; XOR bit 13 and 12  
  SLL R2, R0, #5                  ; MSB is bit 10
  XOR R3, R2, R3                  ; XOR bit 12 and 10  
  SRL R3, R3, #15                 ; MSB to LSB (XOR bit)
  SLL R0, R0, #1                  ; shift one bit to the left
  OR R0, R0, R3                   ; Add XOR bit 
  STR R0, R1, #0                  ; update LFSR  
  
  RTI
