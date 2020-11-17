# Copyright owners: Gentoo Foundation
#                   Arfrever Frehtes Taifersar Arahesis
# Distributed under the terms of the GNU General Public License v2

EAPI="5-progress"

DESCRIPTION="HTML documentation for Python"
HOMEPAGE="https://www.python.org/doc/"
SRC_URI="https://docs.python.org/${PV%.*}/archives/python-${PV}-docs-html.tar.bz2"

LICENSE="PSF-2"
SLOT="3.5"
KEYWORDS="*"
IUSE=""

DEPEND=""
RDEPEND=""

S="${WORKDIR}/python-${PV}-docs-html"

pkg_setup() {
	if has_version "=dev-lang/python-3.5_pre*[doc]"; then
		rm -f "${EROOT}etc/env.d/60python-docs-3.5"
	fi
}

src_install() {
	dohtml -A xml -r ./
	echo "PYTHONDOCS_${SLOT//./_}=\"${EPREFIX}/usr/share/doc/${PF}/html/library\"" > "60python-docs-${SLOT}"
	doenvd "60python-docs-${SLOT}"
}

pkg_postrm() {
	if ! has_version "<dev-python/python-docs-${SLOT}_alpha" && ! has_version ">=dev-python/python-docs-${SLOT%.*}.$((${SLOT#*.}+1))_alpha"; then
		rm -f "${EROOT}etc/env.d/65python-docs"
	fi
}
