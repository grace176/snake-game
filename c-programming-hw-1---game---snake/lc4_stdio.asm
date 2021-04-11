;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  file name   : lc4_stdio.asm                          ;
;  author      : 
;  description : LC4 Assembly subroutines that call     ;
;                call the TRAPs in os.asm (the wrappers);
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
.DATA
.ADDR x2000
STACK_SAVER .FILL 0x0000

;;;  LFSR value used by lfsr code
LFSR .FILL 0x0001

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; WRAPPER SUBROUTINES FOLLOW ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
.CODE
.ADDR x0010    ;; this code should be loaded after line 10
               ;; this is done to preserve "USER_START"
               ;; subroutine that calls "main()"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TRAP_PUTC Wrapper ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.FALIGN
lc4_putc

	;; PROLOGUE ;;
        ;; prologue
	STR R7, R6, #-2	;; save return address
	STR R5, R6, #-3	;; save base pointer
	ADD R6, R6, #-3 ;; update the stack pointer offset of 3
	ADD R5, R6, #0  ;; creates frame pointer

		
	;; FUNCTION BODY ;;
		; TODO: write code to get arguments to the trap from the stack
		;  and copy them to the register file for the TRAP call
        
	LDR R0, R5, #3  ; Loading the contents of R5 with offset of 3 and storing into R0    
	TRAP x01        ; R0 must be set before TRAP_PUTC is called
	
	;; EPILOGUE ;; 
		; TRAP_PUTC has no return value, so nothing to copy back to stack
        
    ;; epilogue
	ADD R6, R5, #0	;; pop locals off stack
	ADD R6, R6, #3	;; free space for return address, base pointer, and return value
	STR R7, R6, #-1	;; store return value
	LDR R5, R6, #-3	;; restore base pointer
	LDR R7, R6, #-2	;; restore return address
RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TRAP_PUTS Wrapper ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.FALIGN
lc4_puts

	;; prologue
	ADD R6, R6, #-2
	STR R5, R6, #0
	STR R7, R6, #1
	
	LEA R7, STACK_SAVER
	STR R6, R7, #0

	;; marshall arguments
	LDR R0, R6, #2

	TRAP x03

	;; epilogue
	LEA R7, STACK_SAVER
	LDR R6, R7, #0

	LDR R7, R6, #1
	LDR R5, R6, #0
	ADD R6, R6, #2
RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TRAP_GETC Wrapper ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.FALIGN
lc4_getc

	;; PROLOGUE ;;
        ; TODO: write prologue code here
    ;; prologue
	STR R7, R6, #-2	;; save return address
	STR R5, R6, #-3	;; save base pointer
	ADD R6, R6, #-3 ;; update the stack pointer offset of 3
	ADD R5, R6, #0  ;; creates frame pointer
		
	;; FUNCTION BODY ;;
		; TODO: TRAP_GETC doesn't require arguments!
		
	TRAP x00        ; Call's TRAP_GETC 
                    ; R0 will contain ascii character from keyboard
                    ; you must copy this back to the stack
	ADD R7, R0, #0  ; store R0 into R7 
    
	;; EPILOGUE ;; 
		; TRAP_GETC has a return value, so make certain to copy it back to stack
    ; epilogue
	ADD R6, R5, #0	;; pop locals off stack
	ADD R6, R6, #3	;; free space for return address, base pointer, and return value
	STR R7, R6, #-1	;; store return value
	LDR R5, R6, #-3	;; restore base pointer
	LDR R7, R6, #-2	;; restore return address
RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TRAP_GETC_TIMER Wrapper ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.FALIGN
lc4_getc_timer

	ADD R6, R6, #-2	
	STR R5, R6, #0
	STR R7, R6, #1

	LDR R0, R6, #2

	LEA R7, STACK_SAVER
	STR R6, R7, #0

	TRAP x05
	
	LEA R7, STACK_SAVER
	LDR R6, R7, #0	

	LDR R7, R6, #1
	;; save TRAP return value on stack
	STR R0, R6, #1
	;; restore user base-pointer
	LDR R5, R6, #0
	ADD R6, R6, #2
RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TRAP_DRAW_RECT Wrapper ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.FALIGN
lc4_draw_rect
    ;; prologue
	ADD R6, R6, #-2
	STR R5, R6, #0
	STR R7, R6, #1
    
	;; marshall arguments
	LDR R0, R6, #2		; x
	LDR R1, R6, #3		; y
	LDR R2, R6, #4		; width
	LDR R3, R6, #5		; height
	LDR R4, R6, #6		; color

	LEA R7, STACK_SAVER
	STR R6, R7, #0
	
	TRAP x09
	
	LEA R7, STACK_SAVER
	LDR R6, R7, #0
	
	;; epilogue
    LDR R7, R6, #1
    LDR R5, R6, #0
	ADD R6, R6, #2
RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TRAP_DRAW_SPRITE Wrapper ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.FALIGN
lc4_draw_sprite
    ;; prologue
	ADD R6, R6, #-2
	STR R5, R6, #0
	STR R7, R6, #1
    
	;; marshall arguments
	LDR R0, R6, #2		; x
	LDR R1, R6, #3		; y
	LDR R2, R6, #4		; color
	LDR R3, R6, #5		; sprite
	
	LEA R7, STACK_SAVER
	STR R6, R7, #0
	
	TRAP x0A
	
	LEA R7, STACK_SAVER
	LDR R6, R7, #0
	
	;; epilogue
	LDR R7, R6, #1
	LDR R5, R6, #0
	ADD R6, R6, #2
    
RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TRAP_LFSR Wrapper ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.FALIGN
lc4_lfsr

    ;;prologue
	ADD R6, R6, #-2	
	STR R5, R6, #0
	STR R7, R6, #1

	LEA R3, LFSR
	LDR R0, R3, 0
	SLL R1, R0,  2		; move bit 13 to MSB
	XOR R2, R0, R1		; xor with bit 15
	SLL R1, R0, 3		; move bit 12 to MSB
	XOR R2, R1, R2
	SLL R1, R0, 5		; move bit 10 to MSB
	XOR R2, R1, R2
	SRL R2, R2, 15		; Shift right logical move MSB to LSB and zeros elsewhere
	SLL R0, R0, 1		; shift left by one bit
	OR  R0, R0, R2		; add in the LSB - note upper bits of R2 are all 0
	STR R0, R3, 0		; update the LFSR in memory
	
	;; save LFSR return value on stack
	STR R0, R6, #1
	;; restore user base-pointer
	LDR R5, R6, #0
	ADD R6, R6, #2
RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TRAP_RESET_VMEM Wrapper ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.FALIGN
lc4_reset_vmem

    ;; STUDENTS - DON'T edit these wrappers - they must be here to get PennSim to work in double-buffer mode
    ;;          - DON'T use their prologue or epilogue's as models - use the slides!!
  
    ;; prologue
	ADD R6, R6, #-2
	STR R5, R6, #0
	STR R7, R6, #1
	;; no arguments
	TRAP x06
	;; epilogue
	LDR R5, R6, #0
	LDR R7, R6, #1
	ADD R6, R6, #2
RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TRAP_BLT_VMEM Wrapper ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.FALIGN
lc4_blt_vmem

    ;; STUDENTS - DON'T edit these wrappers - they must be here to get PennSim to work in double-buffer mode
    ;;          - DON'T use their prologue or epilogue's as models - use the slides!!

	;; prologue
	ADD R6, R6, #-2
	STR R5, R6, #0
	STR R7, R6, #1
	;; no arguments
	TRAP x07
	;; epilogue
	LDR R5, R6, #0
	LDR R7, R6, #1
	ADD R6, R6, #2
RET
