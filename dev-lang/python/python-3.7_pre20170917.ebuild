# Copyright owners: Gentoo Foundation
#                   Arfrever Frehtes Taifersar Arahesis
# Distributed under the terms of the GNU General Public License v2

EAPI="5-progress"
WANT_LIBTOOL="none"

inherit autotools eutils flag-o-matic multilib pax-utils python toolchain-funcs

if [[ "${PV}" == *_pre* ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/python/cpython"
	EGIT_BRANCH="master"
	EGIT_COMMIT="f3618970690b08ed88e430ba8017859b4fafc3f9"
else
	MY_PV="${PV%_p*}"
	MY_P="Python-${MY_PV}"
fi

PATCHSET_REVISION="20170910"

DESCRIPTION="Python is an interpreted, interactive, object-oriented programming language."
HOMEPAGE="https://www.python.org/"
if [[ "${PV}" == *_pre* ]]; then
	SRC_URI=""
else
	SRC_URI="https://www.python.org/ftp/python/${MY_PV}/${MY_P}.tar.xz"
	if [[ "${PR#r}" -lt 1000 ]]; then
		SRC_URI+=" https://home.apache.org/~arfrever/gentoo/python-gentoo-patches-${MY_PV}$([[ "${PATCHSET_REVISION}" != "0" ]] && echo "-r${PATCHSET_REVISION}").tar.bz2"
	fi
fi

LICENSE="PSF-2"
SLOT="3.7"
PYTHON_ABI="${SLOT}"
KEYWORDS="~*"
IUSE="build doc elibc_uclibc examples gdbm ipv6 +ncurses +readline sqlite +ssl tk wininst +xml"

RDEPEND="app-arch/bzip2:0=
		app-arch/xz-utils:0=
		sys-libs/zlib:0=
		virtual/libffi
		virtual/libintl
		!build? (
			gdbm? ( sys-libs/gdbm:0=[berkdb] )
			ncurses? (
				sys-libs/ncurses:0=
				readline? ( sys-libs/readline:0= )
			)
			sqlite? ( >=dev-db/sqlite-3.3.8:3= )
			ssl? ( dev-libs/openssl:0= )
			tk? (
				>=dev-lang/tcl-8.0:0=
				>=dev-lang/tk-8.0:0=
				dev-tcltk/blt:0=
				dev-tcltk/tix
			)
			xml? ( >=dev-libs/expat-2.1:0= )
		)"
DEPEND="${RDEPEND}
		>=sys-devel/autoconf-2.65
		virtual/pkgconfig
		doc? ( dev-python/sphinx )"
RDEPEND+=" !build? ( app-misc/mime-types )"

if [[ "${PV}" != *_pre* ]]; then
	S="${WORKDIR}/${MY_P}"
fi

pkg_setup() {
	python_pkg_setup

	if tc-is-cross-compiler && ! ROOT="/" has_version "${CATEGORY}/${PN}:${SLOT}"; then
		die "Cross-compilation requires ${CATEGORY}/${PN}:${SLOT} installed in host system"
	fi
}

src_prepare() {
	# Ensure that internal copies of expat, libffi and zlib are not used.
	rm -fr Modules/expat
	rm -fr Modules/_ctypes/libffi*
	rm -fr Modules/zlib

	if [[ "${PV}" =~ ^[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+_pre ]]; then
		if grep -Eq '#define PY_RELEASE_LEVEL[[:space:]]+PY_RELEASE_LEVEL_FINAL' Include/patchlevel.h; then
			# Update micro version, release level and version string.
			local micro_version="${PV%_pre*}"
			micro_version="${micro_version##*.}"
			local version_string="${PV%.*}.$((${micro_version} - 1))+"
			sed \
				-e "s/\(#define PY_MICRO_VERSION[[:space:]]\+\)[^[:space:]]\+/\1${micro_version}/" \
				-e "s/\(#define PY_RELEASE_LEVEL[[:space:]]\+\)[^[:space:]]\+/\1PY_RELEASE_LEVEL_ALPHA/" \
				-e "s/\(#define PY_VERSION[[:space:]]\+\"\)[^\"]\+\(\"\)/\1${version_string}\2/" \
				-i Include/patchlevel.h || die "sed failed"
		fi
	fi

	local patchset_dir
	if [[ "${PV}" == *_pre* ]]; then
		patchset_dir="${FILESDIR}/${SLOT}-${PATCHSET_REVISION}"
	elif [[ "${PR#r}" -ge 1000 ]]; then
		patchset_dir="${FILESDIR}/${PV}-${PATCHSET_REVISION}"
	else
		patchset_dir="${WORKDIR}/${MY_PV}"
	fi

	EPATCH_SUFFIX="patch" epatch "${patchset_dir}"

	sed -i -e "s:@@GENTOO_LIBDIR@@:$(get_libdir):g" \
		Lib/distutils/command/install.py \
		Lib/distutils/sysconfig.py \
		Lib/site.py \
		Lib/sysconfig.py \
		Lib/test/test_site.py \
		Makefile.pre.in \
		Modules/Setup.dist \
		Modules/getpath.c \
		configure.ac \
		setup.py || die "sed failed to replace @@GENTOO_LIBDIR@@"

	sed -e "s/test_input_tty_non_ascii/_&/" -i Lib/test/test_builtin.py
	sed -e "s/test_stty_match/_&/" -i Lib/test/test_shutil.py

	sed -e "/if not any(is_multiprocess_flag(arg) for arg in regrtest_args):/,+1d" -i Tools/scripts/run_tests.py

	# Disable ABI flags.
	sed -e "s/ABIFLAGS=\"\${ABIFLAGS}.*\"/:/" -i configure.ac || die "sed failed"

	eaclocal
	eautoconf
	eautoheader
}

src_configure() {
	if use build; then
		# Disable extraneous modules with extra dependencies.
		export PYTHON_DISABLE_MODULES="gdbm _curses _curses_panel readline _sqlite3 _tkinter _elementtree pyexpat"
		export PYTHON_DISABLE_SSL="1"
	else
		local disable
		use gdbm     || disable+=" gdbm"
		use ncurses  || disable+=" _curses _curses_panel"
		use readline || disable+=" readline"
		use sqlite   || disable+=" _sqlite3"
		use ssl      || export PYTHON_DISABLE_SSL="1"
		use tk       || disable+=" _tkinter"
		use xml      || disable+=" _elementtree pyexpat" # _elementtree uses pyexpat.
		export PYTHON_DISABLE_MODULES="${disable}"
	fi

	if [[ -n "${PYTHON_DISABLE_MODULES}" ]]; then
		einfo "Disabled modules: ${PYTHON_DISABLE_MODULES}"
	fi

	if [[ "$(gcc-major-version)" -ge 4 ]]; then
		append-flags -fwrapv
	fi

	filter-flags -malign-double

	[[ "${ARCH}" == "alpha" ]] && append-flags -fPIC

	# https://bugs.gentoo.org/show_bug.cgi?id=50309
	if is-flagq -O3; then
		is-flagq -fstack-protector-all && replace-flags -O3 -O2
		use hardened && replace-flags -O3 -O2
	fi

	# Export CXX so it ends up in /usr/lib/python3.X/config/Makefile.
	tc-export CXX

	local dbmliborder
	if use gdbm; then
		dbmliborder+="${dbmliborder:+:}gdbm"
	fi

	ac_cv_path_PKG_CONFIG="$(tc-getPKG_CONFIG)" OPT="" econf \
		--with-fpectl \
		--enable-shared \
		$(use_enable ipv6) \
		--infodir='${prefix}/share/info' \
		--mandir='${prefix}/share/man' \
		--with-computed-gotos \
		--with-dbmliborder="${dbmliborder}" \
		--without-ensurepip \
		--with-libc="" \
		--enable-loadable-sqlite-extensions \
		--with-system-expat \
		$(use kernel_Darwin && echo --with-system-ffi)
}

src_compile() {
	emake CPPFLAGS="" CFLAGS="" LDFLAGS=""

	if has_version dev-libs/libffi[pax_kernel]; then
		pax-mark E python
	else
		pax-mark m python
	fi

	if use doc; then
		einfo "Generation of documentation"
		cd Doc
		mkdir -p build/{doctrees,html}
		sphinx-build -b html -d build/doctrees . build/html || die "Generation of documentation failed"
	fi
}

src_test() {
	# Tests will not work when cross compiling.
	if tc-is-cross-compiler; then
		elog "Disabling tests due to crosscompiling."
		return
	fi

	# Byte-compilation should be enabled here.
	# Otherwise test_import fails.
	python_enable_byte-compilation

	# Skip failing tests.
	local skipped_tests="gdb"

	for test in ${skipped_tests}; do
		mv Lib/test/test_${test}.py "${T}"
	done

	nonfatal emake test EXTRATESTOPTS="-ucpu,decimal,subprocess,tzdata" CPPFLAGS="" CFLAGS="" LDFLAGS="" < /dev/tty
	local result="$?"

	for test in ${skipped_tests}; do
		mv "${T}/test_${test}.py" Lib/test
	done

	elog "The following tests have been skipped:"
	for test in ${skipped_tests}; do
		elog "test_${test}.py"
	done

	elog "If you would like to run them, you may:"
	elog "cd '${EPREFIX}$(python_get_libdir)/test'"
	elog "and run the tests separately."

	python_disable_byte-compilation

	if [[ "${result}" -ne 0 ]]; then
		die "emake test failed"
	fi
}

src_install() {
	emake DESTDIR="${D}" altinstall
	python_clean_installation_image -q

	sed \
		-e "s/\(CONFIGURE_LDFLAGS=\).*/\1/" \
		-e "s/\(PY_LDFLAGS=\).*/\1/" \
		-i "${ED}$(python_get_libdir)/"config-${SLOT}-*/Makefile || die "sed failed"

	dosym python${SLOT}-config /usr/bin/python-config-${SLOT}

	# Fix collisions between different slots of Python.
	rm -f "${ED}usr/$(get_libdir)/libpython3.so"

	if use build; then
		rm -fr "${ED}usr/bin/idle${SLOT}" "${ED}$(python_get_libdir)/"{idlelib,sqlite3,test,tkinter}
	else
		use elibc_uclibc && rm -fr "${ED}$(python_get_libdir)/test"
		use sqlite || rm -fr "${ED}$(python_get_libdir)/"{sqlite3,test/test_sqlite*}
		use tk || rm -fr "${ED}usr/bin/idle${SLOT}" "${ED}$(python_get_libdir)/"{idlelib,tkinter,test/test_tk*}
	fi

	use wininst || rm -f "${ED}$(python_get_libdir)/distutils/command/"wininst-*.exe

	dodoc Misc/{ACKS,HISTORY}
	if [[ "${PV}" != *_pre* ]]; then
		dodoc Misc/NEWS
	fi

	if use doc; then
		dohtml -A xml -r Doc/build/html/
		echo "PYTHONDOCS_${SLOT//./_}=\"${EPREFIX}/usr/share/doc/${PF}/html/library\"" > "60python-docs-${SLOT}"
		doenvd "60python-docs-${SLOT}"
	fi

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		find Tools -name __pycache__ -print0 | xargs -0 rm -fr
		doins -r Tools
	fi

	newconfd "${FILESDIR}/pydoc.conf" pydoc-${SLOT}
	newinitd "${FILESDIR}/pydoc.init" pydoc-${SLOT}
	sed \
		-e "s:@PYDOC_PORT_VARIABLE@:PYDOC${SLOT/./_}_PORT:" \
		-e "s:@PYDOC@:pydoc${SLOT}:" \
		-i "${ED}etc/conf.d/pydoc-${SLOT}" "${ED}etc/init.d/pydoc-${SLOT}" || die "sed failed"
}

pkg_preinst() {
	if has_version "<${CATEGORY}/${PN}-${SLOT}" && ! has_version ">=${CATEGORY}/${PN}-${SLOT}_alpha"; then
		python_updater_warning="1"
	fi
}

eselect_python_update() {
	if [[ -z "$(eselect python show)" || ! -f "${EROOT}usr/bin/$(eselect python show)" ]]; then
		eselect python update
	fi

	if [[ -z "$(eselect python show --python${PV%%.*})" || ! -f "${EROOT}usr/bin/$(eselect python show --python${PV%%.*})" ]]; then
		eselect python update --python${PV%%.*}
	fi
}

pkg_postinst() {
	eselect_python_update

	python_byte-compile_modules -f -x "/(site-packages|test|tests)/" $(python_get_libdir)

	if [[ "${python_updater_warning}" == "1" ]]; then
		ewarn
		ewarn "\e[1;31m************************************************************************\e[0m"
		ewarn
		ewarn "You have just upgraded from an older version of Python. You should:"
		ewarn "1. Run 'emerge --oneshot sys-apps/portage'"
		ewarn "2. Update potential PYTHON_* variables in make.conf and package.use"
		ewarn "3. Run 'emerge --nodeps --oneshot sys-apps/portage'"
		ewarn "4. Switch active version of Python ${PV%%.*} using 'eselect python'"
		ewarn "5. Run 'emerge --update --deep --newuse @world'"
		ewarn
		ewarn "\e[1;31m************************************************************************\e[0m"
		ewarn
		echo -ne "\a"
	fi
}

pkg_postrm() {
	eselect_python_update

	python_clean_byte-compiled_modules $(python_get_libdir)
}
