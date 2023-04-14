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

# compile MXE cross-compiler
WORKDIR /
RUN git clone https://github.com/mxe/mxe.git
WORKDIR /mxe
# checkout to the last known working/tested (for me...) commit on date of this Dockerfile i.e:
RUN git checkout 76375b2bccbbf409aaab44d4fc0cbd017c5a00e3

# compile the wanted MXE toolchain without CCACHE for space ...
# NOTE SHOULD THIS BE DEACTIVATED FOR PUCLIC SHARE not sure SLA from Xcode allows sharing but crossbuild does it anyway ...
RUN make clean && \
make MXE_USE_CCACHE= DONT_CHECK_REQUIREMENTS=1 MXE_TARGETS="x86_64-w64-mingw32.static i686-w64-mingw32.static" qt5 && \
make MXE_USE_CCACHE= DONT_CHECK_REQUIREMENTS=1 MXE_TARGETS="x86_64-w64-mingw32.static i686-w64-mingw32.static" libiberty && \
make clean-junk

# also install Wine
RUN mkdir -pm755 /etc/apt/keyrings && \
wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bullseye/winehq-bullseye.sources && \
apt update -y -q && \
apt-get install -y --install-recommends winehq-stable

# remove ccache and cleanup
RUN apt-get purge -y ccache && apt-get purge -y aptitude
RUN apt-get install -y ca-certificates zip && apt update -q &&  apt-get upgrade -y && apt-get autoremove -y && apt-get clean -y

RUN rm -rf /var/lib/apt/lists/* && rm -rf /mxe/.log && rm -rf /mxe/.ccache && rm -rf /mxe/pkg && rm -rf /tmp/* && rm -rf /usr/share/man* && rm -rf /usr/share/info*



