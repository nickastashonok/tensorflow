#!/bin/bash -e

target_host=""
toolchain_path=""

prog=compile_nsync_android.sh

usage() {
echo "Usage: $(basename "$0") [t:h:c]"
echo "-t Absolute path to a toolchain"
echo "-h Target host"
echo "-c Clean before building protobuf for target"
echo "\"NDK_ROOT\" should be defined as an environment variable."
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

nsync_builds_dir=tensorflow/contrib/makefile/downloads/nsync/builds

nsync_platform_dir="$nsync_builds_dir/android_distribution"

makefile='
CC='"$toolchain_path"'/bin/clang++
AR='"$toolchain_path"'/bin/llvm-ar
PLATFORM_CPPFLAGS=--sysroot \
'"$toolchain_path"'/sysroot \
-DNSYNC_USE_CPP11_TIMEPOINT -DNSYNC_ATOMIC_CPP11 \
-I../../platform/c++11 -I../../platform/gcc \
-I../../platform/posix -pthread
PLATFORM_CFLAGS=-std=c++11 -Wno-narrowing -fPIE -fPIC
PLATFORM_LDFLAGS=-pthread
MKDEP=${CC} -M -std=c++11
PLATFORM_C=../../platform/c++11/src/nsync_semaphore_mutex.cc \
../../platform/c++11/src/per_thread_waiter.cc \
../../platform/c++11/src/yield.cc \
../../platform/c++11/src/time_rep_timespec.cc \
../../platform/c++11/src/nsync_panic.cc
PLATFORM_OBJS=nsync_semaphore_mutex.o per_thread_waiter.o yield.o \
time_rep_timespec.o nsync_panic.o
TEST_PLATFORM_C=../../platform/c++11/src/start_thread.cc
TEST_PLATFORM_OBJS=start_thread.o
include ../../platform/posix/make.common
include dependfile
'

if [ ! -d "$nsync_platform_dir" ]; then
mkdir "$nsync_platform_dir"
echo "$makefile" | sed $'s,^[ \t]*,,' > "$nsync_platform_dir/Makefile"
touch "$nsync_platform_dir/dependfile"
fi

if (cd "$nsync_platform_dir" && make depend nsync.a >&2); then
echo "$nsync_platform_dir/nsync.a"
mkdir tensorflow/contrib/makefile/gen/nsync
mkdir tensorflow/contrib/makefile/gen/nsync/distribution
mkdir tensorflow/contrib/makefile/gen/nsync/distribution/lib
cp -R $nsync_platform_dir/libnsync.a tensorflow/contrib/makefile/gen/nsync/distribution/lib
else
exit 2
fi

