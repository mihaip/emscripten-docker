ARG EMSDK_VERSION=2.0.12
ARG LLVM_VERSION=11.1.0-rc1
ARG BINARYEN_VERSION=99


FROM --platform=$BUILDPLATFORM ghcr.io/rickardp/cmake-cross:latest AS binaryen
ARG BINARYEN_VERSION
ARG TARGETPLATFORM

RUN git clone https://github.com/WebAssembly/binaryen.git --depth 1 --branch version_${BINARYEN_VERSION}

RUN mkdir -p /binaryen/build

WORKDIR /binaryen/build

RUN cmake -DCMAKE_TOOLCHAIN_FILE=/toolchains/$TARGETPLATFORM -DCMAKE_BUILD_TYPE=Release .. && make -j4

FROM --platform=$BUILDPLATFORM binaryen AS emscripten_base
ARG EMSDK_VERSION
RUN cd / && git clone https://github.com/emscripten-core/emscripten --depth 1 --branch ${EMSDK_VERSION}
COPY --from=binaryen /binaryen/build /binaryen/build

FROM ghcr.io/rickardp/llvm-base:${LLVM_VERSION} AS llvm

RUN apt-get -yq update && apt-get -yq install --no-install-recommends binutils build-essential ca-certificates file git python3 python3-pip nodejs npm cmake

RUN echo "LLVM_ROOT = '/llvm-project/build/bin'" >> /emscripten/.emscripten \
 && echo "BINARYEN_ROOT = '/binaryen/build'" >> /emscripten/.emscripten \
 && echo "NODE_JS = '/usr/bin/node'" >> /emscripten/.emscripten \
 && /emscripten/emcc --help

COPY --from=emscripten_base /binaryen/build /binaryen/build
COPY --from=emscripten_base /emscripten /emscripten

ENV PATH=/emscripten:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /emscripten

