# Copyright owners: Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: waf-utils.eclass
# @MAINTAINER:
# maintainer-needed@gentoo.org
# @AUTHOR:
# Original Author: Gilles Dartiguelongue <eva@gentoo.org>
# Various improvements based on cmake-utils.eclass: Tomáš Chvátal <scarabeus@gentoo.org>
# Proper prefix support: Jonathan Callen <jcallen@gentoo.org>
# @SUPPORTED_EAPIS: 4 4-python 5 5-progress 6
# @BLURB: common ebuild functions for waf-based packages
# @DESCRIPTION:
# The waf-utils eclass contains functions that make creating ebuild for
# waf-based packages much easier.
# Its main features are support of common portage default settings.

[[ ${EAPI} =~ ^(4|4-python|5|5-progress)$ ]] && inherit eutils
inherit multilib toolchain-funcs multiprocessing

case ${EAPI:-0} in
	4|4-python|5|5-progress|6) EXPORT_FUNCTIONS src_configure src_compile src_install ;;
	*) die "EAPI=${EAPI} is not supported" ;;
esac

# @ECLASS-VARIABLE: WAF_VERBOSE
# @DESCRIPTION:
# Set to OFF to disable verbose messages during compilation
# this is _not_ meant to be set in ebuilds
: ${WAF_VERBOSE:=ON}

# @FUNCTION: waf-utils_src_configure
# @DESCRIPTION:
# General function for configuring with waf.
waf-utils_src_configure() {
	debug-print-function ${FUNCNAME} "$@"

	local libdir=()

	# @ECLASS-VARIABLE: WAF_BINARY
	# @DESCRIPTION:
	# Eclass can use different waf executable. Usually it is located in "${S}/waf".
	: ${WAF_BINARY:="${S}/waf"}

	# @ECLASS-VARIABLE: NO_WAF_LIBDIR
	# @DEFAULT_UNSET
	# @DESCRIPTION:
	# Variable specifying that you don't want to set the libdir for waf script.
	# Some scripts does not allow setting it at all and die if they find it.
	[[ -z ${NO_WAF_LIBDIR} ]] && libdir=(--libdir="${EPREFIX}/usr/$(get_libdir)")

	tc-export AR CC CPP CXX RANLIB
	echo "CCFLAGS=\"${CFLAGS}\" LINKFLAGS=\"${CFLAGS} ${LDFLAGS}\" \"${WAF_BINARY}\" --prefix=${EPREFIX}/usr ${libdir[@]} $@ configure"

	CCFLAGS="${CFLAGS}" LINKFLAGS="${CFLAGS} ${LDFLAGS}" "${WAF_BINARY}" \
		"--prefix=${EPREFIX}/usr" \
		"${libdir[@]}" \
		"$@" \
		configure || die "configure failed"
}

# @FUNCTION: waf-utils_src_compile
# @DESCRIPTION:
# General function for compiling with waf.
waf-utils_src_compile() {
	debug-print-function ${FUNCNAME} "$@"
	local _mywafconfig
	[[ ${WAF_VERBOSE} == ON ]] && _mywafconfig="--verbose"

	local jobs="--jobs=$(makeopts_jobs)"
	echo "\"${WAF_BINARY}\" build ${_mywafconfig} ${jobs}"
	"${WAF_BINARY}" ${_mywafconfig} ${jobs} || die "build failed"
}

# @FUNCTION: waf-utils_src_install
# @DESCRIPTION:
# Function for installing the package.
waf-utils_src_install() {
	debug-print-function ${FUNCNAME} "$@"

	echo "\"${WAF_BINARY}\" --destdir=\"${D}\" install"
	"${WAF_BINARY}" --destdir="${D}" install  || die "Make install failed"

	# Manual document installation
	einstalldocs
}
