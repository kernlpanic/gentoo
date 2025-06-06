# Copyright 2021-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
"

LLVM_COMPAT=( {16..19} )

inherit cargo llvm-r1 shell-completion

DESCRIPTION="CLI of the Sequoia OpenPGP implementation"
HOMEPAGE="https://sequoia-pgp.org/ https://gitlab.com/sequoia-pgp/sequoia-sq"
SRC_URI="https://gitlab.com/sequoia-pgp/sequoia-sq/-/archive/v${PV}/${PN}-v${PV}.tar.bz2"
SRC_URI+=" https://github.com/gentoo-crate-dist/${PN}/releases/download/v${PV}/${P}-crates.tar.xz"
S="${WORKDIR}"/${PN}-v${PV}

LICENSE="LGPL-2.1+"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 BSD Boost-1.0 CC0-1.0 ISC LGPL-2+ MIT MIT-0 MPL-2.0
	Unicode-3.0
	|| ( GPL-2 GPL-3 LGPL-3 )
"
SLOT="0"
KEYWORDS="amd64 ~arm64 ~ppc64"

QA_FLAGS_IGNORED="usr/bin/sq"

COMMON_DEPEND="
	dev-db/sqlite:3
	dev-libs/gmp:=
	dev-libs/nettle:=
	dev-libs/openssl:=
"
DEPEND="
	${COMMON_DEPEND}
	dev-libs/capnproto
"
RDEPEND="
	${COMMON_DEPEND}
"
# Clang needed for bindgen
BDEPEND="
	$(llvm_gen_dep '
		llvm-core/clang:${LLVM_SLOT}
	')
	virtual/pkgconfig
"

pkg_setup() {
	llvm-r1_pkg_setup
	rust_pkg_setup
}

src_compile() {
	# Set this here so that it doesn't change if we run tests
	# and cause a recompilation.
	asset_dir="${T}"/assets
	export ASSET_OUT_DIR="${asset_dir}"

	# Setting CARGO_TARGET_DIR is required to have the build system
	# create the bash and zsh completion files.
	export CARGO_TARGET_DIR="${S}/target"
	cargo_src_compile
}

src_install() {
	cargo_src_install

	doman "${asset_dir}"/man-pages/*

	local completion_dir="${asset_dir}"/shell-completions
	newbashcomp "${completion_dir}"/sq.bash sq
	dozshcomp "${completion_dir}"/_sq
	dofishcomp "${completion_dir}"/sq.fish
}
