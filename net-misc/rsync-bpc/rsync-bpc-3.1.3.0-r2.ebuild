# Copyright 2022-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools

DESCRIPTION="Rsync-bpc is a customized version of rsync that is used as part of BackupPC"
HOMEPAGE="https://github.com/backuppc/rsync-bpc"
SRC_URI="https://github.com/backuppc/rsync-bpc/releases/download/${PV}/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="virtual/ssh"
DEPEND="${RDEPEND}"

PATCHES=(
	"${FILESDIR}/${P}-fix-build-issue-on-CentOS6.patch"
	"${FILESDIR}/${P}-fix-22.patch"
	"${FILESDIR}/${P}-fix-buffer-size-on-read-close-write-file-on-read-ope.patch"
	"${FILESDIR}/${P}-free-d-entries-before-free-d-coverity-23.patch"
	"${FILESDIR}/${P}-close-fd-on-error-return-coverity-23.patch"
	"${FILESDIR}/${P}-initialize-fd-and-nRead-separate-malloc-error-messag.patch"
	"${FILESDIR}/${P}-added-free-key-on-error-case-coverity-23.patch"
	"${FILESDIR}/${P}-refCount-needFsck-close-fd.patch"
	"${FILESDIR}/${P}-bpc_poolWrite-Default-to-regular-copy-if-link-rename.patch"
	"${FILESDIR}/${P}-Update-flist.c.patch"
	"${FILESDIR}/${P}-Update-main.c.patch"
	"${FILESDIR}/${P}-Update-bpc_refCount.c.patch"
	"${FILESDIR}/${P}-add-version.h.patch"
	"${FILESDIR}/${P}-update-autoconfig-files.patch"
	"${FILESDIR}/${P}-fix-compile-warnings-on-ubuntu.patch"
	"${FILESDIR}/${P}-update-lib-mdfour.c.patch"
	"${FILESDIR}/${P}-minor-formatting.patch"
	"${FILESDIR}/${P}-minor-tweak.patch"
	"${FILESDIR}/${P}-configure.ac-Avoid-implicit-int-in-AF_INET6-availabi.patch"
	"${FILESDIR}/${P}-fix-gettimeofday-error.patch" #874666
)

src_prepare() {
	default
	sed -i -e 's/AC_HEADER_MAJOR_FIXED/AC_HEADER_MAJOR/' configure.ac
	eaclocal -I m4
	eautoconf -o configure.sh
	eautoheader && touch config.h.in
}

src_configure() {
	econf \
		--disable-md2man \
		--disable-xxhash \
		--disable-lz4
}
