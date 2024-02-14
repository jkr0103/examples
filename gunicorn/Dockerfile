# Stage 1: Compile Gramine

# Please input your base image name in place of `gunicorn-base` below which you would like to 
# graminize
FROM gunicorn-base AS gramine

# Install distro-specific packages to build Gramine (e.g., python3, protobuf, toml, etc.)
RUN env DEBIAN_FRONTEND=noninteractive apt-get update \
    && env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        autoconf \
        bison \
        build-essential \
        coreutils \
        curl \
        gawk \
        git \
        libprotobuf-c-dev \
        linux-headers-generic \
        nasm \
        ninja-build \
        pkg-config \
        protobuf-c-compiler \
        protobuf-compiler \
        python3 \
        python3-cryptography \
        python3-protobuf \
        wget \
        python3-pip \
        && /usr/bin/python3 -B -m pip install 'tomli>=1.1.0' 'tomli-w>=0.4.0' 'meson>=0.56,!=1.2.*'

COPY intel-sgx-deb.key /

RUN echo 'deb [arch=amd64] https://download.01.org/intel-sgx/sgx_repo/ubuntu bionic main' \
    > /etc/apt/sources.list.d/intel-sgx.list \
    && apt-key add /intel-sgx-deb.key

RUN env DEBIAN_FRONTEND=noninteractive apt-get update \
    && env DEBIAN_FRONTEND=noninteractive apt-get install -y libsgx-dcap-quote-verify-dev

RUN git clone --depth 1 --branch v1.6 https://github.com/gramineproject/gramine.git /gramine

RUN mkdir -p /gramine/driver/asm \
    && cd /gramine/driver/asm \
    && wget --timeout=10 -O sgx.h \
        https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/arch/x86/include/uapi/asm/sgx.h?h=v5.11 \
    && sha256sum sgx.h | grep -q a34a997ade42b61376b1c5d3d50f839fd28f2253fa047cb9c0e68a1b00477956

RUN cd /gramine \
    && meson setup build/ --prefix="/gramine/meson_build_output" \
       --buildtype=release \
       -Ddirect=enabled -Dsgx=enabled \
       -Ddcap=enabled \
       -Dsgx_driver=upstream -Dsgx_driver_include_path=/gramine/driver \
    && ninja -C build \
    && ninja -C build install

# Stage 2: Copy Gramine binaries from previous stage
FROM gunicorn-base as unsigned_image
RUN apt-get update \
    && env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        binutils \
        libprotobuf-c-dev \
        locales \
        openssl \
        python3 \
        python3-cryptography \
        python3-protobuf \
        python3-pyelftools \
        python3-pip \
        && /usr/bin/python3 -B -m pip install click jinja2 'tomli>=1.1.0' 'tomli-w>=0.4.0'

RUN locale-gen en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN mkdir -p /gramine/app_files
RUN rm -rf $HOME/.cache
COPY --from=gramine /gramine/meson_build_output /gramine/meson_build_output

# Stage3: Image signing
FROM unsigned_image as signed_image
COPY enclave-key.pem /gunicorn/enclave-key.pem

ENV PATH="/gramine/meson_build_output/bin:$PATH"

RUN export PYTHONPATH="${PYTHONPATH}:$(find /gramine/meson_build_output/lib -type d -path '*/site-packages')" && \
    make SGX=1

# Stage 4: Final GSC image
FROM unsigned_image

COPY --from=signed_image /gunicorn/*.sig /gunicorn/
COPY --from=signed_image /gunicorn/*.sgx /gunicorn/

ENV PATH="/gramine/meson_build_output/bin:$PATH"

ENTRYPOINT ["gramine-sgx", "gunicorn"]
