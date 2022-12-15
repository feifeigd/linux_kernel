
BOOT_HD_IMG = hdBoot1M.img

AS86 = as86 -0 -a

LD86 = ld86 -0

AS = gas
CC = gcc
CFLAGS = -Wall -O -fstrength-reduce -fomit-frame-pointer 

.s.o:
	echo $(AS)
	$(AS) -c -o $*.o $<

all: Image
# Image = boot/boot + tools/system
Image: tools/build boot/boot tools/system
	$^ > Image
	sync

boot/boot: boot/boot.s tools/system
	$(AS86) -o boot/boot.o boot/boot.s
	$(LD86) -s -o $@ boot/boot.o

tools/build: tools/build.cpp
	g++ $(CFLAGS) -o $@ $<

mk_img:
	@if [ ! -e $(BOOT_HD_IMG) ]; then bximage -q -hd=1M -func=create $(BOOT_HD_IMG); fi
