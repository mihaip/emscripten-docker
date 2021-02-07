ARG EMSDK_VERSION=2.0.12
ARG LLVM_VERSION=11.1.0-rc1

FROM ghcr.io/rickardp/llvm-base:${LLVM_VERSION} AS llvm

FROM ubuntu:20.04

RUN cd / && git clone https://github.com/emscripten-core/emsdk

WORKDIR /emsdk

RUN ./emsdk update-tags

# RUN echo ${EMSDK_VERSION} && ./emsdk list &&  ./emsdk install ${EMSDK_VERSION}