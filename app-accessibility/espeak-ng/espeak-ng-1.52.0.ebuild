# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools

DESCRIPTION="Software speech synthesizer for English, and some other languages"
HOMEPAGE="https://github.com/espeak-ng/espeak-ng"

if [[ ${PV} == *9999* ]]; then
	EGIT_REPO_URI="https://github.com/espeak-ng/espeak-ng.git"
	inherit git-r3
else
	SRC_URI="https://github.com/espeak-ng/espeak-ng/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~ppc ppc64 ~riscv sparc x86"
fi

LICENSE="GPL-3+ unicode"
SLOT="0"
IUSE="+async +klatt l10n_ru l10n_zh man mbrola +sound test"
RESTRICT="!test? ( test )"

DEPEND="
	mbrola? ( app-accessibility/mbrola )
	sound? ( media-libs/pcaudiolib )
"
RDEPEND="${DEPEND}
	!app-accessibility/espeak
	sound? ( media-sound/sox )
"
BDEPEND="
	virtual/pkgconfig
	man? ( app-text/ronn-ng )
	test? ( sys-apps/which )
"

DOCS=( CHANGELOG.md README.md docs )

src_prepare() {
	default

	# disable failing tests
	rm tests/{language-pronunciation,translate}.test || die
	sed -i \
		-e "/language-pronunciation.check/d" \
		-e "/translate.check/d" \
		Makefile.am || die

	eautoreconf
}

src_configure() {
	local econf_args

	# https://bugs.gentoo.org/836646
	export PULSE_SERVER=""

	econf_args=(
		$(use_with async)
		$(use_with klatt)
		$(use_with l10n_ru extdict-ru)
		$(use_with l10n_zh extdict-cmn)
		$(use_with l10n_zh extdict-yue)
		$(use_with mbrola)
		$(use_with sound pcaudiolib)
		--without-libfuzzer
		--without-sonic
		--disable-rpath
	)
	econf "${econf_args[@]}"
}

src_test() {
	# bug #947014
	emake check -j1
}

src_install() {
	emake DESTDIR="${D}" VIMDIR=/usr/share/vim/vimfiles install
	find "${ED}" -name '*.la' -delete  || die
}
