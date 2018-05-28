#!/bin/bash -e

target_host=""
toolchain_path=""

usage() {
echo "Usage: $(basename "$0") [t:h:c]"
echo "-t Absolute path to a toolchain"
echo "-h Target host"
echo "-c Clean before building protobuf for target"
exit 1
}

while getopts "h:t:c" opt_name; do
case "$opt_name" in
t) toolchain_path="${OPTARG}";;
h) target_host="${OPTARG}";;
c) clean=true;;
*) usage;;
esac
done
shift $((OPTIND - 1))

if [[ -z "${toolchain_path}" ]]
then
echo "You need to specify toolchain path. Use -t"
exit 1
fi

if [[ -z "${target_host}" ]]
then
echo "You need to specify target host. Use -h"
exit 1
fi

SCRIPT_DIR=$(dirname $0)
source "${SCRIPT_DIR}/build_helper.subr"

if [[ ! -f "${SCRIPT_DIR}/Makefile" ]]; then
echo "Makefile not found in ${SCRIPT_DIR}" 1>&2
exit 1
fi

cd "${SCRIPT_DIR}"
if [ $? -ne 0 ]
then
echo "cd to ${SCRIPT_DIR} failed." 1>&2
exit 1
fi

GENDIR="$(pwd)/gen/protobuf_android"
mkdir -p "${GENDIR}"
HOST_GENDIR="$(pwd)/gen/protobuf-host"
mkdir -p "${HOST_GENDIR}"
DIST_DIR="${GENDIR}/distribution"
mkdir -p "${DIST_DIR}"

if [[ ! -f "./downloads/protobuf/autogen.sh" ]]; then
echo "You need to download dependencies before running this script." 1>&2
echo "tensorflow/contrib/makefile/download_dependencies.sh" 1>&2
exit 1
fi

cd downloads/protobuf

PROTOC_PATH="${HOST_GENDIR}/bin/protoc"
if [[ ! -f "${PROTOC_PATH}" || ${clean} == true ]]; then
echo "protoc not found at ${PROTOC_PATH}. Build it first."
make_host_protoc "${HOST_GENDIR}"
make clean
else
echo "protoc found. Skip building host tools."
fi

export PATH="${toolchain_path}/bin:$PATH"
export CC="${toolchain_path}/bin/clang --sysroot ${toolchain_path}/sysroot"
export CXX="${toolchain_path}/bin/clang++ --sysroot ${toolchain_path}/sysroot"

./autogen.sh
if [ $? -ne 0 ]
then
echo "./autogen.sh command failed."
exit 1
fi

./configure --prefix="${DIST_DIR}" \
--host="${target_host}" \
--with-sysroot="${SYSROOT}" \
--disable-shared \
--enable-cross-compile \
--with-protoc="${PROTOC_PATH}" \
LIBS="-llog -lz"

make
make install

echo "$(basename $0) finished successfully!!!"
