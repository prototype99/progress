# Copyright owners: Gentoo Foundation
#                   Arfrever Frehtes Taifersar Arahesis
# Distributed under the terms of the GNU General Public License v2

EAPI="5-progress"
PYTHON_ABI_TYPE="multiple"
PYTHON_RESTRICTED_ABIS="3.1 *-jython"
PYTHON_TESTS_FAILURES_TOLERANT_ABIS="*"

inherit distutils

DESCRIPTION="Message Passing Interface for Python"
HOMEPAGE="https://bitbucket.org/mpi4py/mpi4py http://pypi.python.org/pypi/mpi4py"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="*"
IUSE="doc examples"

RDEPEND="virtual/mpi[romio]"
DEPEND="${DEPEND}
	$(python_abi_depend dev-python/setuptools)"

PYTHON_CFLAGS=("2.* + -fno-strict-aliasing")

PYTHON_VERSIONED_EXECUTABLES=("/usr/bin/python-mpi")

src_prepare() {
	distutils_src_prepare

	# Automatically run build_exe command.
	sed -e "659d" -i conf/mpidistutils.py || die "sed failed"
}

src_test() {
	testing() {
		PYTHONPATH="$(ls -d build-${PYTHON_ABI}/lib*)" mpiexec -n 2 "$(PYTHON)" test/runtests.py -v
	}
	python_execute_function testing
}

distutils_src_install_post_hook() {
	mkdir -p "$(distutils_get_intermediate_installation_image)${EPREFIX}/usr/bin"
	mv "$(distutils_get_intermediate_installation_image)${EPREFIX}"{$(python_get_sitedir)/mpi4py/bin/python-mpi,/usr/bin}
	rmdir "$(distutils_get_intermediate_installation_image)${EPREFIX}$(python_get_sitedir)/mpi4py/bin"
}

src_install() {
	distutils_src_install

	if use doc; then
		dohtml -r docs/
	fi

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins -r demo/*
	fi
}
