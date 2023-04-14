# start from clean Debian 11.6
FROM debian:11.6

LABEL maintainer="contact@juan.email"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt update -q &&  apt-get upgrade -y && apt-get purge perl

# upgrade to have more repo
RUN echo "deb http://deb.debian.org/debian bullseye main contrib non-free" > /etc/apt/sources.list
RUN echo "deb-src http://deb.debian.org/debian bullseye main contrib non-free" >> /etc/apt/sources.list
RUN echo "deb http://deb.debian.org/debian-security/ bullseye-security main contrib non-free" >> /etc/apt/sources.list
RUN echo "deb-src http://deb.debian.org/debian-security/ bullseye-security main contrib non-free" >> /etc/apt/sources.list
RUN echo "deb http://deb.debian.org/debian bullseye-updates main contrib non-free" >> /etc/apt/sources.list
RUN echo "deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free" >> /etc/apt/sources.list
RUN echo "deb http://deb.debian.org/debian bullseye-backports main contrib non-free" >> /etc/apt/sources.list
RUN echo "deb-src http://deb.debian.org/debian bullseye-backports main contrib non-free" >> /etc/apt/sources.list
RUN apt update -q
RUN apt-get install -y aptitude && \
apt-get purge -y $(aptitude search '~i!~M!~prequired!~pimportant!~R~prequired!~R~R~prequired!~R~pimportant!~R~R~pimportant!busybox!grub!initramfs-tools' | awk '{print $2}') && \
apt-get purge -y aptitude

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
make automake autoconf cmake ninja-build \
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
crossbuild-essential-ppc64el

# install gcc 9 10 from official packages
# install clang 9 11 13
# and java
RUN apt-get install -y gcc g++ gcc-9 g++-9 gcc-10 g++-10 \
clang clang-9 clang-11 clang-13 default-jre default-jdk

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

# requirement for RISC-V cpu target toolchain
RUN apt-get install -y python python3 gcc-multilib \
autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk \
bison flex texinfo gperf libtool patchutils bc zlib1g-dev \
libexpat-dev pkg-config libglib2.0-dev
RUN apt-get -y clean && apt-get -y autoremove

# For debug of image only
#RUN cat /etc/debian_version
#RUN gcc --version && g++ --version && ld --version
#RUN java --version

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
RUN curl -sSL "$OSX_SDK_URL" -o "$OSX_SDK.tar.xz" && \
echo "$OSX_SDK_SHA256SUM $OSX_SDK.tar.xz" | sha256sum --check --status
WORKDIR /tmp/osxcross
COPY patches/lcxx.patch .
RUN patch -p1 < lcxx.patch

RUN SDK_VERSION="${OSX_SDK_VERSION}" OSX_VERSION_MIN=${OSX_TARGET_MIN_VERSION} UNATTENDED=1 ./build.sh
RUN mkdir -p /osxcross && \
mv target /osxcross && \
mv tools /osxcross/

# remove compilation stuff
WORKDIR /tmp
RUN rm -rf /tmp/osxcross && rm -rf "/osxcross/SDK/MacOSX${DARWIN_SDK_VERSION}.sdk/usr/share/man"

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
libswresample-dev libdbus-1-dev libxkbfile-dev libssl-dev llvm-dev && apt-get -y clean && apt-get -y autoremove

WORKDIR /tmp
RUN git clone --recursive https://github.com/darlinghq/darling.git
WORKDIR /tmp/darling
RUN mkdir build && cd build && mkdir /darling
WORKDIR /tmp/darling/build
RUN cmake -G"Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/darling .. && make install && cd /tmp && rm -rf /tmp/darling

ENV PATH $PATH:/darling/bin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/darling/lib

WORKDIR /tmp

# remove ccache and cleanup
RUN apt-get purge -y ccache && apt-get purge -y aptitude
RUN apt-get install -y ca-certificates zip && apt update -q &&  apt-get upgrade -y && apt-get autoremove -y && apt-get clean -y

RUN rm -rf /var/lib/apt/lists/* && rm -rf /mxe/.log && rm -rf /mxe/.ccache && rm -rf /mxe/pkg && rm -rf /tmp/* && rm -rf /usr/share/man* && rm -rf /usr/share/info*

