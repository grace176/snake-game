;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  file name   : factorial_sub.asm                      ;
;  author      : 
;  description : LC4 Assembly subroutine to compute the ;
;                factorial of a number                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;

;; TO-DO:
;; 1) Open up the codio assignment where you created the factorial subroutine (in a separate browswer window)
;; 2) In that window, open up your working factorial_sub.asm file:
;;    -select everything in the file, and "copy" this content (Conrol-C) 
;; 3) Return to the current codio assignment, paste the content into this factorial_sub.asm 
;;    -now you can use the factorial_sub.asm from your last HW in this HW
;; 4) Save the updated factorial_sub.asm file
.FALIGN
SUB_FACTORIAL

;; prologue
	STR R7, R6, #-2	   ; save return address
	STR R5, R6, #-3	   ; save base pointer, at -3 offset
	ADD R6, R6, #-3    ; moving pointer -3 up the stack
	ADD R5, R6, #0     ; moving R5's pointer to where R6 is pointing
	ADD R6, R6, #-1	   ; allocate stack space for local variables, just 1 for this problem, see line 86

  LDR R0, R5, #3    ; load contents of whatever R5 offset +3 is pointing to into R0
  ADD R1, R0 #0     ; before entering loop
  
  CMPI R0, #0         ; sets NZP, what is A - 0
  BRnz END_ERROR      ; tests NZP if A < 0, then go to END_ERROR
  CMPI R0, #7         ; sets NZP, what is A -7
  BRp END_ERROR       ; tests NZP if A > 7, go to END_ERROR
  
LOOP  
  CMPI R0, #1         ; sets NZP (A-1)
  BRnz END_FACTORIAL  ; tests NZP (was A-1 neg or less than 1?, if yes, goto END_FACTORIAL)
  ADD R0, R0, #-1     ; A=A-1
  MUL R1, R1, R0      ; B=B*A
  BRnzp LOOP          ; always goto LOOP
  END_FACTORIAL
RET                   ; end subroutine
END_ERROR
  CONST R1, #-1       ; B = 1
RET                   ; end subroutine 

  ADD R7, R1, #0      ; put the return value back into R7 
  
;; epilogue
	ADD R6, R5, #0	   ;; pop locals off stack
	ADD R6, R6, #3	   ;; free space for return address, base pointer, and return value
	STR R7, R6, #-1	   ;; store return value
	LDR R5, R6, #-3	   ;; restore base pointer
	LDR R7, R6, #-2	   ;; restore return address
    
RET                   ; end subroutine  