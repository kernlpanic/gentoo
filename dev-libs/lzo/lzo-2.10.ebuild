# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit multilib-minimal usr-ldscript

DESCRIPTION="An extremely fast compression and decompression library"
HOMEPAGE="https://www.oberhumer.com/opensource/lzo/"
SRC_URI="https://www.oberhumer.com/opensource/lzo/download/${P}.tar.gz"

LICENSE="GPL-2+"
SLOT="2"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"
IUSE="examples static-libs"

multilib_src_configure() {
	ECONF_SOURCE=${S} \
	econf \
		--enable-shared \
		$(use_enable static-libs static)
}

multilib_src_test() {
	emake test
}

multilib_src_install() {
	emake DESTDIR="${D}" install
	gen_usr_ldscript -a lzo2
}

multilib_src_install_all() {
	rm "${ED}"/usr/share/doc/${PF}/COPYING || die

	if use examples; then
		docinto examples
		dodoc examples/*.{c,h}
	fi

	find "${ED}" -name '*.la' -delete || die
}
