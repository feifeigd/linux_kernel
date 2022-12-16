
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

BOOTSEG = 0x07c0
INITSEG = 0x9000
entry start
start:
; 把启动扇区拷贝到 INITSEG， 并跳转过去继续执行
	mov ax, #BOOTSEG;
	mov ds, ax;

	mov ax, #INITSEG
	mov es, ax;
	mov cx, #256;
	xor si, si
	xor di, di;
	rep 
	movw; 将  ds:si 复制到 es:di

	jmpi go, INITSEG
go:
	mov ax, cs; 跳转之后 cs = INITSEG
	mov ds, ax;
	mov es, ax;
	mov ss, ax;
	mov sp, #0x400; arbitrary value >> 512

; https://blog.csdn.net/liguodong86/article/details/3973337
;功能03H
;功能描述：在文本坐标下，读取光标各种信息
;入口参数：AH＝03H
;BH＝显示页码
;出口参数：CH＝光标的起始行
;CL＝光标的终止行
;DH＝行(Y坐标)
;DL＝列(X坐标)
	mov ah, #0x03; read cursor pos
	xor bh, bh; 显示页码
	int 0x10;

	mov cx, #24; msg1 的长度
	mov bx, #0x0007; page 0, attribute 7(normal)
	mov bp, #msg1
	mov ax, #0x1301; write string, move cursor
	int 0x10

	loop_label: jmp loop_label;

msg1:
	.byte 13, 10
	.ascii "Loading system ..."
	.byte 13, 10, 13, 10
.org 510
	.word 0xAA55

.text
endtext:
.data
enddata:
.bss
endbss:
