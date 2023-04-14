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

# get cygwin cross compiler fro debian packages
# get UPX to compress binaries
RUN apt-get install -y mingw-w64 upx-ucl

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

WORKDIR /tmp

# compile and install gcc 11 and gcc 12 from sources
ARG GCC_SRC_BASE_URL="https://github.com/gcc-mirror/gcc/archive/refs/tags/releases"

ARG GCC_SHORT_VERSION="12"
ARG GCC_FULL_VERSION="12.2.0"
ARG GCC_SRC_PKG_BASENAME="gcc-$GCC_FULL_VERSION"
ARG GCC_SRC_PKG="$GCC_SRC_PKG_BASENAME.tar.gz"
ARG GCC_SRC_PKG_SHA256SUM="ef29a97a0f635e7bb7d41a575129cced1800641df00803cf29f04dc407985df0"
ARG GCC_SRC_URL="$GCC_SRC_BASE_URL/$GCC_SRC_PKG"
RUN wget -q $GCC_SRC_URL && \
echo "$GCC_SRC_PKG_SHA256SUM $GCC_SRC_PKG" | sha256sum --check --status && \
tar -xvf "$GCC_SRC_PKG"
WORKDIR /tmp/gcc-releases-gcc-$GCC_FULL_VERSION
RUN mkdir build && cd build && ../configure -v --build=x86_64-linux-gnu --host=x86_64-linux-gnu --target=x86_64-linux-gnu --prefix=/usr/local/gcc-$GCC_FULL_VERSION --enable-checking=release --enable-languages=c,c++ --disable-multilib --program-suffix=-$GCC_SHORT_VERSION && make -j && make install-strip && cd /tmp && rm -rf /tmp/gcc-*
ENV PATH $PATH:/usr/local/gcc-$GCC_FULL_VERSION/bin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/usr/local/gcc-$GCC_FULL_VERSION/lib:/usr/local/gcc-$GCC_FULL_VERSION/lib64
WORKDIR /tmp

# remove ccache and cleanup
RUN apt-get purge -y ccache && apt-get purge -y aptitude
RUN apt-get install -y ca-certificates zip && apt update -q &&  apt-get upgrade -y && apt-get autoremove -y && apt-get clean -y

RUN rm -rf /var/lib/apt/lists/* && rm -rf /mxe/.log && rm -rf /mxe/.ccache && rm -rf /mxe/pkg && rm -rf /tmp/* && rm -rf /usr/share/man* && rm -rf /usr/share/info*
