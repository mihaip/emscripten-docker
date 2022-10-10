ARG LLVM_VERSION=15.0.0

FROM ubuntu:20.04 AS base
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -yq update && apt-get -yq install --no-install-recommends binutils build-essential ca-certificates file git python3 python3-pip nodejs npm cmake
RUN echo "${TARGETPLATFORM} -- ${BUILDPLATFORM} -- $(uname -m)" >> /img.txt

FROM --platform=$BUILDPLATFORM ghcr.io/mihaip/cmake-cross:latest AS llvm_base
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG LLVM_VERSION
RUN cd / && git clone --depth 1 --branch llvmorg-${LLVM_VERSION} https://github.com/llvm/llvm-project

RUN mkdir -p /llvm-project/tools-build \
 && cd /llvm-project/tools-build \
 && cmake ../llvm -DCMAKE_BUILD_TYPE=Release -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_TESTS=OFF -DLLVM_ENABLE_PROJECTS='lld;clang' -DLLVM_TARGETS_TO_BUILD="host;WebAssembly"

RUN mkdir -p /llvm-project/build \
 && cd /llvm-project/build \
 && cmake ../llvm -DLLVM_USE_HOST_TOOLS=true -DCLANG_TABLEGEN=/llvm-project/tools-build/bin/clang-tblgen -DLLVM_TABLEGEN=/llvm-project/tools-build/bin/llvm-tblgen -DCMAKE_TOOLCHAIN_FILE=/toolchains/$TARGETPLATFORM -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_PROJECTS='lld;clang' -DLLVM_TARGETS_TO_BUILD="host;WebAssembly" -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_TESTS=OFF

RUN cd /llvm-project/tools-build && make -j4 llvm-tblgen && make -j8 clang-tblgen

FROM llvm_base AS llvm_build

RUN cd /llvm-project/build && make -j4

FROM base

COPY --from=llvm_build /llvm-project/build /llvm-project/build

