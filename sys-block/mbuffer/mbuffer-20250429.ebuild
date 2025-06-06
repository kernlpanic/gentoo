# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools optfeature

DESCRIPTION="M(easuring)buffer is a replacement for buffer with additional functionality"
HOMEPAGE="https://www.maier-komor.de/mbuffer.html"
SRC_URI="https://www.maier-komor.de/software/mbuffer/${P}.tgz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~ppc64 ~riscv ~sparc ~x86"
IUSE="debug ssl test"
REQUIRED_USE="test? ( ssl )"
RESTRICT="!test? ( test )"

RDEPEND="
	ssl? (
		dev-libs/openssl
	)
"
DEPEND="${RDEPEND}"

PATCHES=(
	"${FILESDIR}/${PN}-20180410-sysconfdir.patch"
	"${FILESDIR}/${PN}-20200929-find-OBJDUMP.patch"
	"${FILESDIR}/${PN}-20231216-autoconf-warning.patch"
)

src_prepare() {
	default

	ln -s "${DISTDIR}"/${P}.tgz test.tar # bug #258881

	mv configure.in configure.ac || die
	eautoreconf
}

src_configure() {
	local myeconfargs=(
		$(use_enable ssl md5)
		$(use_enable debug)
	)

	econf "${myeconfargs[@]}"
}

src_test() {
	# Enforce MAKEOPTS=-j1 because src_test() spawns multiple listener
	# using same port and src_install may have problems (with /etc folder)
	local -x MAKEOPTS=-j1

	default
}

pkg_postinst() {
	optfeature "autoloader support" app-arch/mt-st
}
