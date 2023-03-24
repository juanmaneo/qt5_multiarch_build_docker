#  Qt5 multiarch build docker
Just another multiarch cross compiling Dockerfile with qt5

This is a multiarch Docker build environment image aimed at cross compilation.
You can use this image to produce binaries for multiple architectures and OS.
It's based of the officila [Debian](https://www.debian.org/) images cf: https://hub.docker.com/_/debian 

## Credit

This docker image is inspired by [crossbuild](https://github.com/multiarch/crossbuild) and [docker-osxcross](https://github.com/crazy-max/docker-osxcross)
Would not be possible without the fantastic [osxcross](https://github.com/tpoechtrager/osxcross) for mac builds
and marvelous [MXE](https://github.com/mxe/mxe) for windows builds

Emulation layers are also included:
[wine](https://gitlab.winehq.org/wine/wine) windows emulation layer is installed via package manager
while [darling](https://github.com/darlinghq/darling) mac emulation is compiled and installed from sources


## Legal note: Notice of Non-Affiliation and Disclaimer

This Docker image is not affiliated with Apple Inc. and does not represent
Apple's official product, service or practice. Apple is not responsible for and
does not endorse this Docker image.

This Docker image is not affiliated with the Xcode project.

**[Please ensure you have read and understood the Xcode license
terms before using it.](https://www.apple.com/legal/sla/docs/xcode.pdf)**

## License

MIT
