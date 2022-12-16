
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

; 1.44MB disks
sectors = 18
; 1.2MB disks
;sectors = 15
; 720KB disks
;sectors = 9

.global begtext, begdata, begbss, endtext, enddata, endbss

.text
begtext:
.data
begdata:

; 未初始化数据段
.bss
begbss:


.text

BOOTSEG = 0x07c0; BIOS 加载启动扇区的原始段地址， 0x7c00物理地址
INITSEG = 0x9000
SYSSEG = 0x1000; system loaded at 0x10000(65536).
SYSSIZE = 219; system的大小，按16字节对齐的单位
ENDSEG = SYSSEG + SYSSIZE

entry start; 程序入口点
start:
; CS:IP = 0x0000:0x7c00
; 把启动扇区拷贝到 INITSEG， 并跳转过去继续执行
	mov ax, #BOOTSEG;
	mov ds, ax;

	mov ax, #INITSEG
	mov es, ax;
	mov cx, #256; 512/2=256，复制一个扇区
	xor si, si
	xor di, di;
	rep 
	movw; 将  ds:si 复制到 es:di

	jmpi go, INITSEG; 段间跳转，标号go是偏移地址
go:
	mov ax, cs; 跳转之后 cs = INITSEG, CS:IP = INITSEG:0x0005
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
	int 0x10; dx = 光标位置(Y, X)

	mov cx, #24; msg1 的长度
	; mov bx, #0x0007; page 0, attribute 7(normal)
	mov bx, #0x000c; page 0, 红色
	mov bp, #msg1
	mov ax, #0x1301; 写字符串并移动光标到串结尾处
	int 0x10

; ok, we've written the message, now we want to load the system(at 0x10000)
	mov ax, #SYSSEG
	mov es, ax; segment of 0x10000
	call read_it; 复制 system
	call kill_motor;

	loop_label: jmp loop_label;
;
; This routine loads the system at address 0x10000, making sure
; no 64kB boundaries are crossed. We try to load it as fast as 
; possible, loading whole tracks whenever we can.
;
; in: es - starting address segment (normally 0x1000)
;
; This routine has to be recompiled to fit another drive type,
; just change the "sectors" variable at the start of the file
; (originally 18, for a 1.44MB drive)
;
sread: .word 1; sectors read of current track；扇区号，从1开始
head: .word 0; current head; 磁头号
track: .word 0; current track; 磁道号

read_it:
	mov ax, es;
	test ax, #0x0fff; test只是进行and操作，不返回结果，目的是改变标志位
die:jne die; es must be at 64kB boundary
	xor bx, bx; bx is starting address within segment
rp_read:
	mov ax, es;
	cmp ax, #ENDSEG; have we loaded all yet?
	jb ok1_read; ax < #ENDSEG
	ret;
ok1_read:
	mov ax, #sectors; 一共需要读多少个扇区
	sub ax, sread; 当前磁道在读的扇区号
	mov cx, ax; 剩余多少扇区要读
	shl cx, #9; 乘以 512，变成字节数
	add cx, bx;
	jnc ok2_read; 没有进位
	je ok2_read; 刚好读取了64KB
	xor ax, ax
	sub ax, bx;
	shr ax, #9; 除以 512，变成还要读多少扇区
ok2_read:
	call read_track;
	mov cx, ax; al 存了读取完成的扇区个数
	add ax, sread
	cmp ax, #sectors
	jne ok3_read; 未读完
	; 看要不要变更磁头和磁道
	mov ax, #1
	sub ax, head
	jne ok4_read
	inc track; 当前磁道track，磁头0和1都读过了，读下一个磁道
ok4_read:
	mov head, ax; 切换磁头号 head，0 -> 1; 1 -> 0
	xor ax, ax; 切换磁头之后，重置扇区号
ok3_read:
	mov sread, ax; 更新当前磁道的扇区号
	shl cx, #9
	add bx, cx
	jnc rp_read; CF只跟 add等运算指令有关
	mov ax, es
	add ax, #0x1000; 读下一个64KB
	mov es, ax
	xor bx, bx; 偏移量复位 es:bx 
	jmp rp_read

read_track:
	push ax;
	push bx;
	push cx;
	push dx;

	mov dx, track; 磁道号
	mov cx, sread; 扇区号
	inc cx;
	mov ch, dl; ch 磁道号的低8位

	; 设置驱动器号，磁头号
	mov dx, head
	mov dh, dl
	mov dl, 0; 驱动器号，若是硬盘则要置位7
	and dx, #0x0100; dh=磁头号，软盘有两个面

	mov ah, #2; 读磁盘扇区到内存
	int 0x13; 读的数据存到 es:bx 

	jc bad_rt; 出错了

	pop dx;
	pop cx;
	pop bx;
	pop ax;
	ret;

bad_rt:; 出错则复位软盘驱动器
	mov ax, #0
	mov dx, #0
	int 0x13

	pop dx;
	pop cx;
	pop bx;
	pop ax;

	jmp read_track;

;
; This procedure turns off the floppy drive motor, so that
; we enter the kernel in a known state, and don't have to worry about it later.
;
kill_motor:
	push ax
	mov dx, #0x3f2
	mov al, #0
	pop ax
	ret;

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
