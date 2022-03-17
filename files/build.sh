#!/bin/bash

build_dir=/tmp/build
smcutil_dir=${build_dir}/smc_util
tinycore_dir=${build_dir}/tinycore
grub_dir=${build_dir}/grub
supergrub_dir=${build_dir}/supergrub
tdm_dir=${build_dir}/tdm
output_dir=/tmp/output


function my_trap_handler()
{
        MYSELF="$0"
        LASTLINE="$1"            # argument 1: last line of error occurence
        LASTERR="$2"             # argument 2: error code of last command
        echo "${MYSELF}: line ${LASTLINE}: exit status of last command: ${LASTERR}"

	# abort on failure
	exit 1
}

# divert errors to trap handler
trap 'my_trap_handler ${LINENO} ${$?}' ERR

# check if ISO source looks halfway legit, or bail out
echo ${TC_ISO_URL} | grep -Ee '^https?://(www\.)?tinycorelinux\.net/[0-9]+.*/.*\.iso' >/dev/null || { echo "Error: invalid ISO download source"; false; }


# build SMC utility from https://github.com/floe/smc_util
printf "## STAGE 1: build smc_util\n"
mkdir -p ${build_dir} 
git clone https://github.com/floe/smc_util.git ${smcutil_dir}
cd ${smcutil_dir}
cc -O2 -o SmcDumpKey SmcDumpKey.c -Wall


# fetch TinyCore ISO and extract it
printf "## STAGE 2: fetch TinyCore ISO\n"
mkdir -p ${tinycore_dir}
wget "${TC_ISO_URL}" -O ${tinycore_dir}/Core-current.iso
xorriso -osirrox on -indev ${tinycore_dir}/Core-current.iso -extract / ${tinycore_dir}/Core-current


# package it
printf "## STAGE 3: Make TDM tce package\n"
## NOTE: ${tdm_dir} and substructure is included when container is staged
## 	 the mkdir's below are thus NOT necessary
## mkdir -p ${tdm_dir}/usr/bin/ ${tdm_dir}/etc/init.d/services/
cp ${smcutil_dir}/SmcDumpKey ${tdm_dir}/usr/bin/ 
chmod 755 ${tdm_dir}/usr/bin/* ${tdm_dir}/etc/init.d/services/tdm ${tdm_dir}/usr/local/tce.installed/tdm

mkdir -p ${tinycore_dir}/Core-current/cde/optional
mksquashfs ${tdm_dir} ${tinycore_dir}/Core-current/cde/optional/tdm.tcz
echo tdm.tcz >> ${tinycore_dir}/Core-current/cde/onboot.lst


# assemble the output files
printf "## STAGE 4: assemble output files\n"
printf ">> pre cleanup\n"
rm -rf ${output_dir}/*

printf ">> grub.cfg\n"
[ ! -d ${output_dir}/boot ] && mkdir -p ${output_dir}/boot
[ ! -d ${output_dir}/boot/grub ] && mkdir -p ${output_dir}/boot/grub
cp -rpv ${grub_dir}/* ${output_dir}/boot/grub


printf ">> EFI loader\n"
[ ! -d ${output_dir}/efi ] && mkdir -p ${output_dir}/efi
[ ! -d ${output_dir}/efi/boot ] && mkdir -p ${output_dir}/efi/boot
cp -rpv ${supergrub_dir}/super_grub2_disk_standalone_x86_64_efi_2.04s1.EFI ${output_dir}/efi/boot/bootX64.efi

printf ">> remastered TinyCore ISO\n"
[ ! -d ${output_dir}/boot-isos ] && mkdir -p ${output_dir}/boot-isos
xorriso -as mkisofs -l -J -r -V TC-custom -no-emul-boot \
	-boot-load-size 4 \
	-boot-info-table -b boot/isolinux/isolinux.bin \
	-c boot/isolinux/boot.cat -o ${output_dir}/boot-isos/Core-remastered.iso ${tinycore_dir}/Core-current

printf "## STAGE 5: process completed\n"
