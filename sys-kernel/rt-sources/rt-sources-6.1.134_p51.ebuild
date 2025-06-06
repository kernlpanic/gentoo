# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"
ETYPE="sources"

CKV="$(ver_cut 1-3)"
K_SECURITY_UNSUPPORTED="1"
K_DEBLOB_AVAILABLE="1"
RT_PATCHSET="${PV/*_p}"

inherit kernel-2
detect_version

K_BRANCH_ID="${KV_MAJOR}.${KV_MINOR}"
DESCRIPTION="Full Linux ${K_BRANCH_ID} kernel sources with the CONFIG_PREEMPT_RT patch"
HOMEPAGE="https://wiki.linuxfoundation.org/realtime/start"

RT_FILE="patch-${K_BRANCH_ID}.${KV_PATCH}-rt${RT_PATCHSET}.patch.xz"
RT_URI="https://www.kernel.org/pub/linux/kernel/projects/rt/${K_BRANCH_ID}/${RT_FILE} \
		https://www.kernel.org/pub/linux/kernel/projects/rt/${K_BRANCH_ID}/older/${RT_FILE}"

SRC_URI="${KERNEL_URI} ${RT_URI}"
KV_FULL="${PVR/_p/-rt}"
S="${WORKDIR}/linux-${KV_FULL}"
KEYWORDS="~amd64 ~arm64"

UNIPATCH_LIST="${DISTDIR}/${RT_FILE}"
UNIPATCH_STRICTORDER="yes"

src_prepare() {
	default

	# 627796
	sed \
		"s/default PREEMPT_NONE/default PREEMPT_RT/g" \
		-i "${S}/kernel/Kconfig.preempt" || die "sed failed"
}

pkg_postinst() {
	kernel-2_pkg_postinst
	ewarn
	ewarn "${PN} are *not* supported by the Gentoo Kernel Project in any way."
	ewarn "If you need support, please contact the RT project developers directly."
	ewarn "Do *not* open bugs in Gentoo's bugzilla unless you have issues with"
	ewarn "the ebuilds."
	ewarn
}

K_EXTRAEINFO="For more info on rt-sources and details on how to report problems, see: \
${HOMEPAGE}."
