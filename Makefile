
BOOT_HD_IMG = hdBoot1M.img

mk_img:
	@if [ ! -e $(BOOT_HD_IMG) ]; then bximage -q -hd=1M -func=create $(BOOT_HD_IMG); fi
