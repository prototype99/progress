# Copyright owners: Arfrever Frehtes Taifersar Arahesis
# Distributed under the terms of the GNU General Public License v2

EAPI="5-progress"
PYTHON_ABI_TYPE="multiple"
PYTHON_RESTRICTED_ABIS="3.1 3.2 *-jython"

inherit distutils

MY_PN="cryptography_vectors"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Test vectors for the cryptography package."
HOMEPAGE="https://cryptography.io/ https://github.com/pyca/cryptography https://pypi.python.org/pypi/cryptography-vectors"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${MY_P}.tar.gz"

LICENSE="|| ( Apache-2.0 BSD )"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="$(python_abi_depend dev-python/setuptools)"
RDEPEND=""

S="${WORKDIR}/${MY_P}"

PYTHON_MODULES="cryptography_vectors"
