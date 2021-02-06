ARG EMSDK_VERSION=2.0.12
ARG LLVM_VERSION=11.1.0-rc1

FROM ubuntu:20.04 AS base
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -yq update && apt-get -yq install --no-install-recommends binutils build-essential ca-certificates file git python3 python3-pip nodejs npm cmake
RUN echo "${TARGETPLATFORM} -- ${BUILDPLATFORM} -- $(uname -m)" >> /img.txt

FROM --platform=$BUILDPLATFORM ghcr.io/rickardp/cmake-cross:latest AS llvm_build
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG LLVM_VERSION
RUN cd / && git clone --depth 1 --branch llvmorg-${LLVM_VERSION} https://github.com/llvm/llvm-project

RUN mkdir -p /llvm-project/build \
 && cd /llvm-project/build \
 && cmake ../llvm -DCMAKE_TOOLCHAIN_FILE=/toolchains/$TARGETPLATFORM -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_PROJECTS='lld;clang' -DLLVM_TARGETS_TO_BUILD="host;WebAssembly" -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_TESTS=OFF

#RUN cd /llvm-project/build && cmake --build . --parallel 8
RUN echo "${TARGETPLATFORM} -- ${BUILDPLATFORM} -- $(uname -m)" >> /llvm-project/build/img.txt

WORKDIR /llvm-project

FROM base AS emscripten_base

ARG EMSDK_VERSION

RUN cd / && git clone https://github.com/emscripten-core/emsdk

# WORKDIR /emsdk

# RUN ./emsdk update-tags

# RUN echo ${EMSDK_VERSION} && ./emsdk list &&  ./emsdk install ${EMSDK_VERSION}

FROM base AS emsdk

COPY --from=llvm_build /llvm-project/build /llvm-project/build

