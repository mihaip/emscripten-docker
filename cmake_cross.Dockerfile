#
# This image produces a multi-platform cross compiler with cmake. It can build
# both arm64 and x86_64 on both arm64 and x86_64. It is needed until GitHub actions
# gains Arm64 native support.
#

FROM ubuntu:20.04
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -yq update && apt-get -yq install --no-install-recommends \
  build-essential \
  ca-certificates \
  cmake \
  git \
  binutils-aarch64-linux-gnu \
  binutils-x86-64-linux-gnu \
  gcc-x86-64-linux-gnu \
  gcc-aarch64-linux-gnu \
  g++-x86-64-linux-gnu \
  g++-aarch64-linux-gnu \
  python3 \
  python3-pip \
  file \
  && rm -rf /var/cache/apt

RUN mkdir -p /toolchains/linux \
  && echo "set(CMAKE_SYSTEM_NAME Linux)" > /toolchains/linux/aarch64 \
  && echo "set(CMAKE_SYSTEM_NAME Linux)" > /toolchains/linux/amd64 \
  && echo "set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)" >> /toolchains/linux/aarch64 \
  && echo "set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)" >> /toolchains/linux/amd64 \
  && echo "set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)" >> /toolchains/linux/aarch64 \
  && echo "set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)" >> /toolchains/linux/amd64 \
  && echo "set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)" >> /toolchains/linux/aarch64 \
  && echo "set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)" >> /toolchains/linux/amd64 \
  && echo "set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)" >> /toolchains/linux/aarch64 \
  && echo "set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)" >> /toolchains/linux/amd64 \
  && echo "set(CMAKE_SYSTEM_PROCESSOR aarch64)" >> /toolchains/linux/aarch64 \
  && echo "set(CMAKE_SYSTEM_PROCESSOR x86_64)" >> /toolchains/linux/amd64 \
  && echo "set(CMAKE_C_COMPILER /usr/bin/aarch64-linux-gnu-gcc-9)" >> /toolchains/linux/aarch64 \
  && echo "set(CMAKE_C_COMPILER /usr/bin/x86_64-linux-gnu-gcc-9)" >> /toolchains/linux/amd64 \
  && echo "set(CMAKE_CXX_COMPILER /usr/bin/aarch64-linux-gnu-g++-9)" >> /toolchains/linux/aarch64 \
  && echo "set(CMAKE_CXX_COMPILER /usr/bin/x86_64-linux-gnu-g++-9)" >> /toolchains/linux/amd64 \
  && echo "set(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu)" >> /toolchains/linux/aarch64 \
  && echo "set(CMAKE_FIND_ROOT_PATH /usr/x86_64-linux-gnu)" >> /toolchains/linux/amd64 \
  && echo "set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE arm64)" >> /toolchains/linux/aarch64 \
  && echo "set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE amd64)" >> /toolchains/linux/amd64 \
  && ln -s /toolchains/linux/aarch64 /toolchains/linux/arm64 \
  && ln -s /toolchains/linux/amd64 /toolchains/linux/x86_64

# Create test program
RUN mkdir -p /test \
  && echo "#include <stdio.h>\nint main() {printf(\"Hello world\\\\n\");return 0;}" > /test/test.c \
  && echo "project(TEST)\nadd_executable(test test.c)" > /test/CMakeLists.txt \
  && mkdir -p /test/build/aarch64 && cd /test/build/aarch64 && cmake -DCMAKE_TOOLCHAIN_FILE=/toolchains/linux/aarch64 ../.. && make \
  && mkdir -p /test/build/amd64 && cd /test/build/amd64 && cmake -DCMAKE_TOOLCHAIN_FILE=/toolchains/linux/amd64 ../.. && make \
  && md5sum /test/build/*/test > /test/status && file /test/build/*/test >> /test/status \
  && echo "${TARGETPLATFORM} -- ${BUILDPLATFORM} -- $(uname -m)" > /test/arch
