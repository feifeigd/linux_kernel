
BOOT_HD_IMG = hdBoot1M.img

# -0 使用16比特代码段; -a 开启GNU as、ld的部分兼容性选项
AS86 = as86 -0 -a
# 产生16比特魔数的头结构，并且对 -lx选项使用i86子目录
LD86 = ld86 -0

AS = as
LD = ld
LDFLAGS = -s -x -e main -M
CC = gcc
CFLAGS = -Wall -O -fstrength-reduce -fomit-frame-pointer 
CPP = gcc -E -nostdinc -Iinclude

.c.o:
	$(CC) $(CFLAGS) -nostdinc -Iinclude -o $*.o $<

.c.s:
	$(CC) $(CFLAGS) -nostdinc -Iinclude -S -o $*.s $<

.s.o:
	echo $(AS)
	$(AS) -c -o $*.o $<

all: Image
# Image = boot/boot + tools/system
Image: tools/build boot/boot tools/system
	$^ > Image
	sync

backup: clean
	(cd ..; tar -cf - linux | compress - > backup.Z)
	sync

# boot/boot 是 a.out 格式
boot/boot: boot/boot.s tools/system
	$(AS86) -o boot/boot.o $<
	$(LD86) -s -o $@ boot/boot.o

clean:
	rm -f Image System.map tmp_make boot/boot core
	rm -f init/*.o boot/*.o tools/build tools/system 

dep:
	sed '/\#\#\# Dependencies/q' < Makefile > tmp_make
	(for i in init/*.c; do echo -n "init/";$(CPP) -M $$i;done) >> tmp_make


tools: tools/build tools/predef tools/system

tools/build: tools/build.cpp
	g++ $(CFLAGS) -o $@ $<
tools/predef: tools/predef.cpp
	g++ $(CFLAGS) -o $@ $<
tools/system: init/main.o
	$(LD) $(LDFLAGS) $^ $(ARCHIVES) $(LIBS) -o $@ > System.map

mk_img:
	@if [ ! -e $(BOOT_HD_IMG) ]; then bximage -q -hd=1M -func=create $(BOOT_HD_IMG); fi

### Dependencies:
init/main.o: init/main.c
