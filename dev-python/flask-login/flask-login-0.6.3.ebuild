# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1

DESCRIPTION="Login session support for Flask"
HOMEPAGE="
	https://github.com/maxcountryman/flask-login/
	https://pypi.org/project/Flask-Login/
"
SRC_URI="
	https://github.com/maxcountryman/flask-login/archive/${PV}.tar.gz
		-> ${P}.gh.tar.gz
"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 arm arm64 ~ppc ~ppc64 ~riscv ~sparc x86"

RDEPEND="
	>=dev-python/flask-1.0.4[${PYTHON_USEDEP}]
	>=dev-python/werkzeug-2.3.0[${PYTHON_USEDEP}]
"
DEPEND="
	test? (
		dev-python/asgiref[${PYTHON_USEDEP}]
		dev-python/blinker[${PYTHON_USEDEP}]
		dev-python/semantic-version[${PYTHON_USEDEP}]
	)
"

distutils_enable_sphinx docs
distutils_enable_tests pytest

python_test() {
	local -x PYTEST_DISABLE_PLUGIN_AUTOLOAD=1
	epytest
}
