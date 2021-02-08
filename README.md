# Multi-arch Emscripten SDK image for CI and dev containers

The purpose of this project is to provide a tagged base image for building emscripten projects for building, as well
as being able to use as a development container to provide a baseline development experience.

Another goal of this project is to provide an up to date build/dev exeprience for the Arm64 platform (including Raspberry Pi and the Apple Silicon).

## How this image is built
This project first builds a cross-compilation-aware cmake image. The purpose of this image is to make sure the
heavy lifting of the compilation is done on the native platform (necessary to build locally and also since the
GitHub actions does not support ARM64 natively and QEMU is slow enough that compilation jobs will time out).

The cmake image is published to `ghcr.io/rickardp/cmake-cross` and is intended to be used like this

    FROM --platform=$BUILDPLATFORM ghcr.io/rickardp/cmake-cross AS build
    RUN cmake ....

    FROM <some_base> AS runtime
    COPY --from=build ...

Then built with e.g.

   docker buildx build --platform linux/arm64/v8,linux/amd64 .

This ensures the compilation is done natively while still building multiarch images.
