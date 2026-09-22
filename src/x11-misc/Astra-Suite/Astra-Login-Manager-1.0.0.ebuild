# Copyright 2026 Gentoo Authors
# Distributed under the terms of the MIT License

EAPI=8

CRATES="
# YOUR CRATES LIST WILL GO HERE (See note below)
"

inherit cargo

DESCRIPTION="Quickshell-based, Rust-coded login manager"
HOMEPAGE="https://github.com/Astra-WM/Astra-Login-Manager"
SRC_URI="
	https://github.com{PV}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"

S="${WORKDIR}/Astra-Login-Manager-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

# Runtime dependencies
RDEPEND="
	gui-apps/quickshell
"
DEPEND="${RDEPEND}"

src_install() {
	# Installs the compiled binary from target/release/ directly to /usr/bin/
	cargo_src_install
	
	einstalldocs
}
