---
title: Fixing Grub after installing Windows 7
date: 2009-05-16T05:25:00
author: Graham Wheeler
category: Computers
slug: fixing-grub-after-installing-windows-7
---

I have an MSI Wind on which I run both Windows 7 and Ubuntu. I rarely
use the latter but I like to keep it around and with a 320GB hard drive
its affordable. I have used both the Windows BCD loader and GRUB as my
bootloader at various times (and for those using BCD I highly recommend
[EasyBCD](http://neosmart.net/dl.php?id=1) as the way to configure it).
Most recently I've been using GRUB.

Yesterday I installed Windows 7 RC and my boot sector got clobbered by
BCD. I had a bit of a had time getting things working again. I first
tried using EasyBCD but this time when trying to boot Ubuntu I ended up
at a GRUB prompt, and I could not access my Ubuntu partition (more
precisely, while "root (hd0,2)" worked, "kernel /vmlinuz" threw errrors
and I could not boot).
<!-- TEASER_END -->

In the end I got things working using the Ubuntu live CD and
reinstalling GRUB. However, it required more than just doing a
grub-install - for some reason the BIOS drive mappings seem to have been
messed up. I did a web search and I found a lot of people have had this
problem and very few found the solution so I thought it was worth
mentioning what I did to make mine work in the hope it is useful to
others.

In my case my primary Ubuntu partition is the 3rd partition; i.e.
/dev/sda3. After booting the live CD and opening the terminal, here is
the set of commands I used to get things working again:

    sudo mount /dev/sda3 /mnt
    sudo mount -t proc /proc /mnt/proc
    sudo mount --bind /dev /mnt/dev
    sudo chroot /mnt
    grub-install --recheck /dev/sda
    update-grub

Without the mounts of /proc and /dev, /dev/sda won't be found after the
chroot. The --recheck option is necessary because somehow the BIOS drive
mappings have gotten confused. It's possible the update-grub step is not
necessary but I think it is safest to rebuild the grub config; I read at
one web posting where someone omitted this step and after rebooting was
left at the GRUB prompt again.
