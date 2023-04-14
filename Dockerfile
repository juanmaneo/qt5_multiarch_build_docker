# start from clean Debian 11.6
FROM debian:11.6

LABEL maintainer="contact@juan.email"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -y clean && apt-get -y autoremove && apt update -q && apt-get upgrade -y && apt-get purge perl && apt-get -y clean && apt-get -y autoremove

# upgrade to have more repo
RUN echo "deb http://deb.debian.org/debian bullseye main contrib non-free" > /etc/apt/sources.list
RUN echo "deb-src http://deb.debian.org/debian bullseye main contrib non-free" >> /etc/apt/sources.list
RUN echo "deb http://deb.debian.org/debian-security/ bullseye-security main contrib non-free" >> /etc/apt/sources.list
RUN echo "deb-src http://deb.debian.org/debian-security/ bullseye-security main contrib non-free" >> /etc/apt/sources.list
RUN echo "deb http://deb.debian.org/debian bullseye-updates main contrib non-free" >> /etc/apt/sources.list
RUN echo "deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free" >> /etc/apt/sources.list
RUN echo "deb http://deb.debian.org/debian bullseye-backports main contrib non-free" >> /etc/apt/sources.list
RUN echo "deb-src http://deb.debian.org/debian bullseye-backports main contrib non-free" >> /etc/apt/sources.list
RUN apt update -q && apt-get install -y aptitude && apt-get purge -y $(aptitude search '~i!~M!~prequired!~pimportant!~R~prequired!~R~R~prequired!~R~pimportant!~R~R~pimportant!busybox!grub!initramfs-tools' | awk '{print $2}') && apt-get purge -y aptitude && dpkg --add-architecture amd64

# basic tools
RUN apt-get install -y libc6-dev libc-dev-bin \
make automake autoconf cmake ninja-build \
build-essential gcc g++ clang default-jre default-jdk \
clang-format clang-tidy astyle \
api-sanity-checker libgtest-dev libboost-all-dev pkg-config \
locales bzip2 tar gzip unzip zip lzip p7zip-full parallel \
curl wget git swig && apt-get -y clean && apt-get -y autoremove

WORKDIR /tmp

# compile and install clang 16 from sources

# First install lld faster linker from clang 16 source code 
ARG CLANG_SRC_VERSION=16.0.1
RUN git clone https://github.com/llvm/llvm-project.git && cd llvm-project && git checkout llvmorg-$CLANG_SRC_VERSION
WORKDIR /tmp/llvm-project
RUN cmake -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_PROJECTS=lld -DCMAKE_INSTALL_PREFIX=/usr -S llvm -B build -G Ninja && ninja -C build install && cd /tmp && rm -rf /tmp/llvm-project
WORKDIR /tmp

# then clang 15
ARG CLANG_SRC_VERSION=15.0.7
RUN git clone https://github.com/llvm/llvm-project.git && cd llvm-project && git checkout llvmorg-$CLANG_SRC_VERSION
WORKDIR /tmp/llvm-project
RUN cmake -DCMAKE_BUILD_TYPE=Release -DLLVM_USE_LINKER=lld -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;compiler-rt" -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" -DCMAKE_INSTALL_PREFIX=/usr -S llvm -B build -G Ninja && ninja -C build runtimes && ninja -C build install && cd /tmp && rm -rf /tmp/llvm-project
WORKDIR /tmp

# install missing Gtest
RUN apt-get install -y googletest

# remove ccache and cleanup
RUN apt-get purge -y ccache && apt-get purge -y aptitude && apt-get install -y ca-certificates zip && apt update -q && apt-get upgrade -y && apt-get autoremove -y && apt-get autoclean -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* && rm -rf /mxe/.log && rm -rf /mxe/.ccache && rm -rf /mxe/pkg && rm -rf /tmp/* && rm -rf /usr/share/man* && rm -rf /usr/share/info*
