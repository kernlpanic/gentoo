# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic libtool toolchain-funcs

MY_PN=imap
MY_P="${MY_PN}-${PV}"

DESCRIPTION="UW IMAP c-client library"
HOMEPAGE="http://www.washington.edu/imap/"
SRC_URI="
	ftp://ftp.cac.washington.edu/imap/${MY_PN}-$(ver_cut 1-2).tar.Z
	mirror://debian/pool/main/u/uw-${MY_PN}/uw-${MY_PN}_${PV/_p/"~dfsg-"}.debian.tar.xz
"
S="${WORKDIR}"/${MY_PN}-$(ver_cut 1-2)

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="doc +ipv6 kerberos pam ssl static-libs topal"

RDEPEND="
	ssl? (
		dev-libs/openssl:=
	)
	kernel_linux? (
		pam? ( >=sys-libs/pam-0.72 )
		!pam? ( virtual/libcrypt:= )
	)
	kerberos? ( app-crypt/mit-krb5 )
"
DEPEND="${RDEPEND}"

PATCHES=(
	"${WORKDIR}"/debian/patches

	# Apply a patch to only build the stuff we need for c-client
	"${FILESDIR}/${PN}-2006k_GENTOO_Makefile.patch"

	# Apply patch to add the compilation of a .so for PHP
	# This was previously conditional, but is more widely useful.
	"${FILESDIR}/${PN}-2007f_GENTOO_amd64-so-fix.patch"

	# Respect LDFLAGS
	"${FILESDIR}/${PN}-2007f_p7-ldflags.patch"

	# build fix for -Werror=implicit-function-declaration and
	# incompatible function pointer types, bug #870478 and bug #919252
	"${FILESDIR}/${PN}-2007f-scandir-callback-types.patch"
	"${FILESDIR}/${PN}-2007f_p7-implicit-declaration-fix.patch"
	"${FILESDIR}/${PN}-2007f_p7-c99.patch"
)

src_prepare() {
	use topal && PATCHES+=( "${FILESDIR}/${PN}-2007f-topal.patch" )

	default

	# Tarball packed with bad file perms
	chmod -R u+rwX,go-w . || die "failed to fix permissions"

	# Lots of things need -fPIC, including various platforms, and this library
	# generally should be built with it anyway.
	append-flags -fPIC

	# Modifications so we can build it optimally and correctly
	sed \
		-e "s:BASECFLAGS=\".*\":BASECFLAGS=:g" \
		-e 's:SSLDIR=/usr/local/ssl:SSLDIR=/usr:g' \
		-e 's:SSLCERTS=$(SSLDIR)/certs:SSLCERTS=/etc/ssl/certs:g' \
		-i src/osdep/unix/Makefile \
		|| die "failed to fix compiler flags and SSL paths in the Makefile"

	# Make the build system more multilib aware
	sed \
		-e "s:^SSLLIB=\$(SSLDIR)/lib:SSLLIB=\$(SSLDIR)/$(get_libdir):" \
		-e "s:^AFSLIB=\$(AFSDIR)/lib:AFSLIB=\$(AFSDIR)/$(get_libdir):" \
		-i src/osdep/unix/Makefile \
		|| die "failed to fix our libdir in the Makefile"

	# Targets should use the Gentoo (ie linux) fs
	sed -e '/^bsf:/,/^$/ s:ACTIVEFILE=.*:ACTIVEFILE=/var/lib/news/active:g' \
		-i src/osdep/unix/Makefile \
		|| die "failed to fix the FreeBSD ACTIVEFILE path in the Makefile"

	# Remove the pesky checks about SSL stuff
	sed -e '/read.*exit/d' -i Makefile \
		|| die "failed to disable SSL warning in the Makefile"

	sed -e "s:CC=cc:CC=$(tc-getCC):" \
		-e "s:ARRC=ar:ARRC=$(tc-getAR):" \
		-e "s:RANLIB=ranlib:RANLIB=$(tc-getRANLIB):" \
		-i src/osdep/unix/Makefile \
		|| die "failed to fix build flags support in the Makefile"

	sed -i -e "s:krb5-config.mit:krb5-config:" src/osdep/unix/Makefile.gss || die

	elibtoolize
}

src_compile() {
	local mymake target passwdtype

	local ipver='IP=4'
	if use ipv6 ; then
		ipver="IP=6"
		touch ip6 || die "failed to create ip6 file"
	fi

	local ssltype="none"
	if use ssl ; then
		ssltype="unix"
	fi

	if use kernel_linux ; then
		# Fall back to "slx" when USE=pam is not set. This ensures that
		# we link in libcrypt to get the crypt() routine (bug #456928).
		use pam && target=lnps passwdtype=pam || target=slx passwdtype=std
	fi

	if use kerberos ; then
		mymake="EXTRAAUTHENTICATORS=gss"
		EXTRALIBS="-lgssapi_krb5 -lkrb5 -lk5crypto -lcom_err"
	fi

	emake -j1 \
		SSLTYPE=${ssltype} ${target} \
		PASSWDTYPE=${passwdtype} ${ipver} ${mymake} \
		EXTRACFLAGS="${CFLAGS}" \
		EXTRALDFLAGS="${LDFLAGS}" \
		EXTRALIBS="${EXTRALIBS}" \
		GSSDIR=/usr
}

src_install() {
	if use static-libs; then
		# Library binary
		dolib.a c-client/c-client.a
		dosym c-client.a "/usr/$(get_libdir)/libc-client.a"
	fi

	# Now the shared library
	dolib.so c-client/libc-client.so.1.0.0

	dosym libc-client.so.1.0.0 "/usr/$(get_libdir)/libc-client.so"
	dosym libc-client.so.1.0.0 "/usr/$(get_libdir)/libc-client.so.1"

	# Headers
	insinto /usr/include/imap
	doins src/osdep/unix/*.h
	doins src/c-client/*.h
	doins c-client/linkage.h
	doins c-client/linkage.c
	doins c-client/osdep.h

	if use ssl; then
		echo "  ssl_onceonlyinit ();" >> "${D}"/usr/include/imap/linkage.c \
			|| die "failed to add ssl init statement to linkage.c"
	fi

	# Documentation
	dodoc README docs/*.txt docs/BUILD docs/CONFIG docs/RELNOTES docs/SSLBUILD
	if use doc; then
		docinto rfc
		dodoc docs/rfc/*.txt
		docinto draft
		dodoc docs/draft/*
	fi
}
