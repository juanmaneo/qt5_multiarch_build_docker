# start from clean Debian 11.6
FROM debian:11.6

LABEL maintainer="contact@juan.email"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt update -q &&  apt-get upgrade -y && apt-get purge perl

# prepare cross compilers
RUN dpkg --add-architecture amd64 && \
dpkg --add-architecture arm64 && \
dpkg --add-architecture armel && \
dpkg --add-architecture armhf && \
dpkg --add-architecture i386 && \
dpkg --add-architecture mips && \
dpkg --add-architecture mipsel && \
dpkg --add-architecture powerpc && \
dpkg --add-architecture ppc64el

# basic tools
RUN apt-get install -y libc6-dev libc-dev-bin \
make automake autoconf \
build-essential \
binutils-multiarch \
binutils-multiarch-dev \
crossbuild-essential-amd64 \
crossbuild-essential-arm64 \
crossbuild-essential-armel \
crossbuild-essential-armhf \
crossbuild-essential-i386 \
crossbuild-essential-mips \
crossbuild-essential-mips64 \
crossbuild-essential-mipsel \
crossbuild-essential-powerpc \
crossbuild-essential-ppc64el \
cmake

# install gcc 9 10 and 11
RUN apt-get install -y gcc g++ gcc-10 g++-10 gcc-9 g++-9

# install clang 9 11 and 13
RUN apt-get install -y clang clang-11 clang-13 clang-9

# install clang-format so we can replace Astyle
# and also install clang-tidy
RUN apt-get install -y clang-format clang-tidy astyle

# dependency for OSXCross Linux to macOS (aka: mac OS X)
RUN apt-get install -y zlib1g-dev libmpc-dev libmpfr-dev libgmp-dev

# tool to get line of code statistics
RUN apt-get install -y cccc

# install api-sanity-checker in case we want to use it
RUN apt-get install -y api-sanity-checker libgtest-dev libboost-all-dev pkg-config \
locales bzip2 tar gzip unzip zip lzip p7zip-full parallel \
curl wget git swig

# dependency for MXE linux to Windows cross compiler
RUN apt-get install -y autopoint bison flex gperf ruby scons \
-y intltool libtool libtool-bin \
nsis gnupg libharfbuzz-dev libgdk-pixbuf2.0-dev \
python-dev python3-dev \
binutils-dev

RUN apt-get install -y default-jre default-jdk

# to be able to build QT from source
RUN apt-get install -y mesa-common-dev libfontconfig1 \
qtbase5-dev qt5-qmake qtbase5-dev-tools

# add the same stuff as in crossbuild images
RUN apt-get install -y -q autotools-dev                \
        bc                                             \
        binfmt-support                                 \
        ccache                                         \
        curl                                           \
        devscripts                                     \
        gdb                                            \
        git-core                                       \
        libtool                                        \
        llvm                                           \
        mercurial                                      \
        multistrap                                     \
        patch                                          \
        software-properties-common                     \
        subversion                                     \
        wget                                           \
        xz-utils                                       \
        cmake                                          \
        qemu-user-static                               \
        libxml2-dev                                    \
        lzma-dev                                       \
        openssl                                        \
        libssl-dev

# get cygwin cross compiler fro debian packages
RUN apt-get install -y mingw-w64

# requirement for RISC-V cpu target toolchain
RUN apt-get install -y python python3 gcc-multilib \
autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk \
bison flex texinfo gperf libtool patchutils bc zlib1g-dev \
libexpat-dev pkg-config libglib2.0-dev

RUN cat /etc/debian_version
RUN gcc --version && g++ --version && ld --version
RUN java --version

# compile MXE cross-compiler
WORKDIR /
RUN git clone https://github.com/mxe/mxe.git
WORKDIR /mxe
# checkout to the last known working/tested (for me...) commit on date of this Dockerfile i.e:
RUN git checkout 76375b2bccbbf409aaab44d4fc0cbd017c5a00e3

# compile the wanted MXE toolchain without CCACHE for space ...
# NOTE SHOULD THIS BE DEACTIVATED FOR PUCLIC SHARE not sure SLA from Xcode allows sharing but crossbuild does it anyway ...
RUN make clean
RUN make MXE_USE_CCACHE= DONT_CHECK_REQUIREMENTS=1 MXE_TARGETS="x86_64-w64-mingw32.static i686-w64-mingw32.static" qt5
RUN make MXE_USE_CCACHE= DONT_CHECK_REQUIREMENTS=1 MXE_TARGETS="x86_64-w64-mingw32.static i686-w64-mingw32.static" libiberty
RUN make clean-junk

# also install Wine
RUN mkdir -pm755 /etc/apt/keyrings
RUN wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
RUN wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bullseye/winehq-bullseye.sources
RUN apt update -y -q
RUN apt-get install -y --install-recommends winehq-stable

## You should be able to compile and use osxcross if you want from a Mac normally
## Please ensure you have read and understood the Xcode license terms USING this docker file/image
## cf: https://www.apple.com/legal/sla/docs/xcode.pdf

ARG osxcross_repo="tpoechtrager/osxcross"
ARG osxcross_revision="542acc2ef6c21aeb3f109c03748b1015a71fed63"

ARG OSX_CROSS_COMMIT="50e86ebca7d14372febd0af8cd098705049161b9"
ARG OSX_SDK_VERSION="12.3" # Monterey
ARG OSX_TARGET_MIN_VERSION="10.15" # Catalina
ARG OSX_SDK="MacOSX${OSX_SDK_VERSION}.sdk"
ARG OSX_SDK_URL="https://github.com/joseluisq/macosx-sdks/releases/download/${OSX_SDK_VERSION}/${OSX_SDK}.tar.xz"
ARG OSX_SDK_SHA256SUM="3abd261ceb483c44295a6623fdffe5d44fc4ac2c872526576ec5ab5ad0f6e26c"

WORKDIR /tmp
RUN git clone https://github.com/tpoechtrager/osxcross.git
WORKDIR /tmp/osxcross
RUN git checkout $OSX_CROSS_COMMIT
WORKDIR /tmp/osxcross/tarballs
RUN curl -sSL "$OSX_SDK_URL" -o "$OSX_SDK.tar.xz"
RUN echo "$OSX_SDK_SHA256SUM $OSX_SDK.tar.xz" | sha256sum --check --status
WORKDIR /tmp/osxcross
COPY patches/lcxx.patch .
RUN patch -p1 < lcxx.patch

RUN SDK_VERSION="${OSX_SDK_VERSION}" OSX_VERSION_MIN=${OSX_TARGET_MIN_VERSION} UNATTENDED=1 ./build.sh
RUN mkdir -p /osxcross
RUN mv target /osxcross                                                                                    
RUN mv tools /osxcross/

# remove compilation stuff
WORKDIR /tmp
RUN rm -rf /tmp/osxcross
# remove manpage
RUN rm -rf "/osxcross/SDK/MacOSX${DARWIN_SDK_VERSION}.sdk/usr/share/man"

# Create symlinks for triples and set default CROSS_TRIPLE
ENV LINUX_TRIPLES=arm-linux-gnueabi,arm-linux-gnueabihf,aarch64-linux-gnu,mipsel-linux-gnu,powerpc64le-linux-gnu                  \
    DARWIN_TRIPLES=x86_64h-apple-darwin${DARWIN_VERSION},x86_64-apple-darwin${DARWIN_VERSION},i386-apple-darwin${DARWIN_VERSION}  \
    WINDOWS_TRIPLES=i686-w64-mingw32,x86_64-w64-mingw32                                                                           \
    CROSS_TRIPLE=x86_64-linux-gnu
COPY ./assets/osxcross-wrapper /usr/bin/osxcross-wrapper
RUN mkdir -p /usr/x86_64-linux-gnu;                                                               \
    for triple in $(echo ${LINUX_TRIPLES} | tr "," " "); do                                       \
      for bin in /usr/bin/$triple-*; do                                                           \
        if [ ! -f /usr/$triple/bin/$(basename $bin | sed "s/$triple-//") ]; then                  \
          ln -s $bin /usr/$triple/bin/$(basename $bin | sed "s/$triple-//");                      \
        fi;                                                                                       \
      done;                                                                                       \
      for bin in /usr/bin/$triple-*; do                                                           \
        if [ ! -f /usr/$triple/bin/cc ]; then                                                     \
          ln -s gcc /usr/$triple/bin/cc;                                                          \
        fi;                                                                                       \
      done;                                                                                       \
    done &&                                                                                       \
    for triple in $(echo ${DARWIN_TRIPLES} | tr "," " "); do                                      \
      mkdir -p /usr/$triple/bin;                                                                  \
      for bin in /osxcross/bin/$triple-*; do                                                      \
        ln /usr/bin/osxcross-wrapper /usr/$triple/bin/$(basename $bin | sed "s/$triple-//");      \
      done &&                                                                                     \
      rm -f /usr/$triple/bin/clang*;                                                              \
      ln -s cc /usr/$triple/bin/gcc;                                                              \
      ln -s /osxcross/SDK/MacOSX${DARWIN_SDK_VERSION}.sdk/usr /usr/x86_64-linux-gnu/$triple;      \
    done;                                                                                         \
    for triple in $(echo ${WINDOWS_TRIPLES} | tr "," " "); do                                     \
      mkdir -p /usr/$triple/bin;                                                                  \
      for bin in /etc/alternatives/$triple-* /usr/bin/$triple-*; do                               \
        if [ ! -f /usr/$triple/bin/$(basename $bin | sed "s/$triple-//") ]; then                  \
          ln -s $bin /usr/$triple/bin/$(basename $bin | sed "s/$triple-//");                      \
        fi;                                                                                       \
      done;                                                                                       \
      ln -s gcc /usr/$triple/bin/cc;                                                              \
      ln -s /usr/$triple /usr/x86_64-linux-gnu/$triple;                                           \
    done

# we need to use default clang binary to avoid a bug in osxcross that recursively call himself
# with more and more parameters

ENV PATH /osxcross/bin:$PATH
ENV LD_LIBRARY_PATH /osxcross/lib:$LD_LIBRARY_PATH

# restore macOS behavior of clang in OSXCross
ARG OSXCROSS_GCC_NO_STATIC_RUNTIME=1
ARG OSXCROSS_ENABLE_WERROR_IMPLICIT_FUNCTION_DECLARATION=1

# install Darling (aka like Wine but for MacOS)
# first the requirements
RUN apt-get install -y -q bison flex xz-utils libfuse-dev libudev-dev pkg-config \
libc6-dev-i386 libcap2-bin git git-lfs python2 libglu1-mesa-dev libcairo2-dev \
libgl1-mesa-dev libtiff5-dev libfreetype6-dev libxml2-dev libegl1-mesa-dev libfontconfig1-dev \
libbsd-dev libxrandr-dev libxcursor-dev libgif-dev libpulse-dev libavformat-dev libavcodec-dev \
libswresample-dev libdbus-1-dev libxkbfile-dev libssl-dev llvm-dev

RUN apt-get -y clean && apt-get -y autoremove

WORKDIR /tmp
RUN git clone --recursive https://github.com/darlinghq/darling.git
WORKDIR /tmp/darling
RUN mkdir build && cd build && mkdir /darling
WORKDIR /tmp/darling/build
RUN cmake -G"Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/darling ..
RUN make install
WORKDIR /tmp
RUN rm -rf /tmp/darling

ENV PATH $PATH:/darling/bin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/darling/lib

RUN rm -rf

# remove ccache
RUN apt-get -y purge ccache

RUN apt-get -y clean && apt-get -y autoremove
RUN rm -rf /var/lib/apt/lists/* && rm -rf /mxe/.log && rm -rf /mxe/pkg && rm -rf /tmp/* && rm -rf /usr/share/man* && rm -rf /usr/share/info*

