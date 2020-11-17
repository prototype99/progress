# Copyright owners: Gentoo Authors
#                   Arfrever Frehtes Taifersar Arahesis
# Distributed under the terms of the GNU General Public License v2

EAPI="5-progress"

inherit flag-o-matic multilib-minimal toolchain-funcs versionator

MAJOR_VERSION="$(get_version_component_range 1)"
if [[ "${PV}" =~ ^[[:digit:]]+_rc[[:digit:]]*$ ]]; then
	MINOR_VERSION="1"
else
	MINOR_VERSION="$(get_version_component_range 2)"
fi

DESCRIPTION="International Components for Unicode"
HOMEPAGE="http://www.icu-project.org/ https://github.com/unicode-org/icu"

BASE_URI="http://download.icu-project.org/files/icu4c/${PV/_/}"
SRC_ARCHIVE="icu4c-${PV//./_}-src.tgz"
DOCS_ARCHIVE="icu4c-${PV//./_}-docs.zip"

SRC_URI="${BASE_URI}/${SRC_ARCHIVE}
	doc? ( ${BASE_URI}/${DOCS_ARCHIVE} )"

LICENSE="BSD"
SLOT="0/${MAJOR_VERSION}"
KEYWORDS="*"
IUSE="debug doc examples static-libs"

# virtual/pkgconfig needed if eautoreconf used.
DEPEND=""
RDEPEND=""

S="${WORKDIR}/${PN}/source"

QA_DT_NEEDED="/usr/lib.*/libicudata\.so\.${MAJOR_VERSION}\.${MINOR_VERSION}.*"
QA_FLAGS_IGNORED="/usr/lib.*/libicudata\.so\.${MAJOR_VERSION}\.${MINOR_VERSION}.*"

MULTILIB_CHOST_TOOLS=(
	/usr/bin/icu-config
)

pkg_pretend() {
	if tc-is-gcc; then
		if ! test-flag-CXX -std=gnu++14; then
			eerror "GCC >=4.9 required for support for C++14"
			die "C++14 not supported by currently used C++ compiler"
		fi
	else
		if ! test-flag-CXX -std=c++14; then
			die "C++14 not supported by currently used C++ compiler"
		fi
	fi
}

src_unpack() {
	unpack "${SRC_ARCHIVE}"
	if use doc; then
		mkdir docs
		pushd docs > /dev/null
		unpack "${DOCS_ARCHIVE}"
		popd > /dev/null
	fi
}

src_prepare() {
	if tc-is-gcc; then
		# Disable automatic detection of version of C++ standard.
		append-cxxflags -std=gnu++14
	else
		# Disable automatic detection of version of C++ standard.
		append-cxxflags -std=c++14
	fi

	sed \
		-e "s/#define U_DISABLE_RENAMING 0/#define U_DISABLE_RENAMING 1/" \
		-e "s/#define UCONFIG_ENABLE_PLUGINS 0/#define UCONFIG_ENABLE_PLUGINS 1/" \
		-i common/unicode/uconfig.h || die "sed failed"

	multilib_copy_sources
}

multilib_src_configure() {
	econf \
		--enable-dyload \
		--disable-layoutex \
		--enable-plugins \
		--disable-renaming \
		$(use_enable debug) \
		$(use_enable examples samples) \
		$(use_enable static-libs static) \
		CC="$(tc-getCC)" \
		CXX="$(tc-getCXX)"
}

multilib_src_compile() {
	emake VERBOSE="1"
}

multilib_src_test() {
	if [[ "${ABI}" == "x86" ]]; then
		# https://unicode-org.atlassian.net/browse/ICU-13222
		sed -e "/TESTCASE(TestRelDateFmt)/d" -i test/cintltst/crelativedateformattest.c

		# https://unicode-org.atlassian.net/browse/ICU-10614
		sed -e "/TESTCASE_AUTO(testGetSamples)/d" -i test/intltest/plurults.cpp
	fi

	# INTLTEST_OPTS: intltest options
	#   -e: Exhaustive testing
	#   -l: Reporting of memory leaks
	#   -v: Increased verbosity
	# IOTEST_OPTS: iotest options
	#   -e: Exhaustive testing
	#   -v: Increased verbosity
	# CINTLTST_OPTS: cintltst options
	#   -e: Exhaustive testing
	#   -v: Increased verbosity
	emake -j1 VERBOSE="1" check
}

multilib_src_install() {
	emake DESTDIR="${D}" VERBOSE="1" install
}

multilib_src_install_all() {
	(
		docinto html
		dodoc ../readme.html
	)
	if use doc; then
		(
			docinto html/api
			dodoc -r "${WORKDIR}/docs/"*
		)
	fi
}
