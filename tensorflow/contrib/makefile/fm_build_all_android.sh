#!/usr/bin/env bash

set -e

if [[ -z "${NDK_ROOT}" ]]; then
echo "NDK_ROOT should be set as an environment variable" 1>&2
exit 1
fi

target_host=""
toolchain_path=""
architecture=""

usage() {
echo "Usage: $(basename "$0") [t:h:a:c]"
echo "-t Absolute path to a toolchain"
echo "-h Target host"
echo "-a Architecture"
echo "-c Clean before building protobuf for target"
echo "\"NDK_ROOT\" should be defined as an environment variable."
exit 1
}

SCRIPT_DIR=$(dirname $0)

while getopts "h:t:a:c" opt_name; do
case "$opt_name" in
t) toolchain_path="${OPTARG}";;
h) target_host="${OPTARG}";;
a) architecture="${OPTARG}";;
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

if [[ -z "${architecture}" ]]
then
echo "You need to specify architecture. Use -a"
exit 1
fi

# Make sure we're in the correct directory, at the root of the source tree.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
cd "${SCRIPT_DIR}"/../../../

make -f tensorflow/contrib/makefile/Makefile cleantarget
rm -rf tensorflow/contrib/makefile/downloads
rm -rf tensorflow/contrib/makefile/gen
tensorflow/contrib/makefile/download_dependencies.sh
tensorflow/contrib/makefile/fm_compile_android_protobuf.sh -t ${toolchain_path} -h ${target_host}
tensorflow/contrib/makefile/fm_compile_android_nsync.sh -t ${toolchain_path} -h ${target_host}
HOST_NSYNC_LIB=`tensorflow/contrib/makefile/compile_nsync.sh`
export HOST_NSYNC_LIB

make -f tensorflow/contrib/makefile/Makefile TARGET=ANDROID ANDROID_TOOLCHAIN=${toolchain_path} ANDROID_HOST=${target_host} ANDROID_ARCH=${architecture}
