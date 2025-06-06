# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools flag-o-matic toolchain-funcs

DESCRIPTION="GNU Linear Programming Kit"
HOMEPAGE="https://www.gnu.org/software/glpk/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0/40"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~ppc ppc64 ~riscv sparc x86 ~amd64-linux ~x86-linux"
IUSE="doc examples gmp odbc mysql"

BDEPEND="virtual/pkgconfig"
DEPEND="
	sci-libs/amd:0=
	sci-libs/colamd:=
	sys-libs/zlib:0=
	gmp? ( dev-libs/gmp:0= )
	mysql? (
		dev-db/mysql-connector-c
		dev-libs/libltdl
	)
	odbc? (
		|| (
			dev-db/libiodbc:0
			dev-db/unixODBC:0
		)
		dev-libs/libltdl
	)"
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}"/${PN}-4.65-fix-mysql-include-prefix.patch
	"${FILESDIR}"/${PN}-4.65-debundle-system-libs.patch
	"${FILESDIR}"/${PN}-5.0-aliasing.patch
)

src_prepare() {
	# TODO: the ODBC library is dlopen()ed, so we only want to append
	# -I<foo> to the preprocessor flags, and not all of the CFLAGS that
	# were used to build libiodbc. That fix and the pkg-config fallback
	# should be sent upstream, and placed into CPPFLAGS rather than
	# CFLAGS (as configure.ac does now).
	use odbc && [[ -z $(type -P odbc_config) ]] && \
		append-cppflags $($(tc-getPKG_CONFIG) --cflags libiodbc)

	# Newer GNU standards fail to compile thanks to "bool", while using
	# ISO C17 breaks thread safety... and also fails to compile.
	append-cflags -std=gnu17

	default

	eautoreconf
}

src_configure() {
	local myconf
	if use mysql || use odbc; then
		myconf="--enable-dl"
	else
		myconf="--disable-dl"
	fi

	econf ${myconf} \
		--disable-static \
		$(use_enable mysql) \
		$(use_enable odbc) \
		$(use_with gmp)
}

src_install() {
	default

	if use examples; then
		# The top-level Makefile descends into the "examples" directory
		# unconditionally, building a program and excreting build
		# artifacts that we don't want to install. Note: this still
		# leaves the example program /usr/bin/glpsol installed. An
		# additional "emake ... uninstall" could probably take care
		# of that if desired.
		emake -C examples clean

		# Installing the Makefiles for the examples does the user no
		# good without the top-level Makefile.
		rm examples/Makefile{.in,.am,} \
			|| die "failed to remove example Makefiles"

		insinto "/usr/share/doc/${PF}"
		doins -r examples
		docompress -x "/usr/share/doc/${PF}/examples"
	fi

	use doc && dodoc doc/*.pdf doc/notes/*.pdf doc/*.txt

	# no static archives
	find "${D}" -name '*.la' -delete || die
}
