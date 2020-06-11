#!/bin/bash
# RELEASE SCRIPT FOR NAEV
#
# This script attempts to compile and build different parts of Naev
# automatically in order to prepare for a new release. Files will  be written
# to the "dist/" directory.
#
# Steam sdk should be unpacked, set up, and named "steam/" in the naev directory.

if [[ ! -f "naev.6" ]]; then
   echo "Please run from Naev root directory."
   exit -1
fi

NAEVDIR="$(pwd)"
OUTPUTDIR="${NAEVDIR}/dist/"
STEAMPATH="${NAEVDIR}/steam/tools/linux/"
LOGFILE="release.log"
CFLAGS="-j5"

function log {
   echo "$1" >> "${LOGFILE}"
}

function get_version {
   VERSION="$(cat ${NAEVDIR}/VERSION)"
   # Get version, negative minors mean betas
   if [[ -n $(echo "${VERSION}" | grep "-") ]]; then
      BASEVER=$(echo "${VERSION}" | sed 's/\.-.*//')
      BETAVER=$(echo "${VERSION}" | sed 's/.*-//')
      VERSION="${BASEVER}.0-beta${BETAVER}"
   fi
}

function make_generic {
   log "Compiling $2"
   make distclean
   ./autogen.sh
   ./configure $1
   make ${CFLAGS}
   get_version
   mv src/naev "${OUTPUTDIR}/naev-${VERSION}-$2"
}

function make_linux_64 {
   make_generic "--enable-lua=internal" "linux-x86-64"
}

function make_linux_steam_64 {
   log "Compiling linux-steam-x86-64"
   TMPPATH="/tmp/naev_steam_compile.sh"
   echo "#!/bin/bash" > "${TMPPATH}"
   echo "make distclean" >> "${TMPPATH}"
   echo "./autogen.sh" >> "${TMPPATH}"
   echo "./configure --enable-lua=internal --without-libzip" >> "${TMPPATH}"
   echo "make ${CFLAGS}" >> "${TMPPATH}"
   chmod +x "${TMPPATH}"
   ${STEAMPATH}/shell-amd64.sh "${TMPPATH}"
   get_version
   mv src/naev "${OUTPUTDIR}/naev-${VERSION}-linux-steam-x86-64"
}

function make_source {
   log "Making source bzip2"
   VERSIONRAW="$(cat ${NAEVDIR}/VERSION)"
   make dist-bzip2
   get_version
   mv "naev-${VERSIONRAW}.tar.bz2" "dist/naev-${VERSION}-source.tar.bz2"
}

function make_ndata {
   log "Making ndata"
   get_version
   make "ndata.zip"
   mv "ndata.zip" "${OUTPUTDIR}/ndata-${VERSION}.zip"
}

# Create output dirdectory if necessary
test -d "$OUTPUTDIR" || mkdir "$OUTPUTDIR"

# Set up log
touch "${LOGFILE}"

# Preparation
make distclean
./autogen.sh
./configure --enable-lua=internal --enable-csparse=internal
make VERSION

# Make stuff
make_source
make_ndata
make_linux_64
make_linux_steam_64

