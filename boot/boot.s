
; boot.s
; boot.s is loaded at 0x7c00 by the bios-startup routines, and moves itself
; out of the way to address 0x90000, and jumps there.
;
; It then loads the system at 0x10000, using BIOS interrupts. Thereafter
; it disables all interrupts, moves the system down to 0x0000, changes 
; RE-initialize the protected mode in it's own tables, and enable 
; interrupts as needed.
;
; NOTE! currently system is at most 8 * 65536 bytes long. This shouldbe no 
; problem, even in the future. I want to keep 

.global begtext, begdata, begbss, endtext, enddata, endbss

.text
begtext:
.data
begdata:
.bss
begbss:


.text
entry start
start:
	mov ax, bx;
	loop_label: jmp loop_label;

.org 510
	.word 0xAA55

.text
endtext:
.data
enddata:
.bss
endbss:
