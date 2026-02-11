# syntax=docker/dockerfile:1

# Build this Dockerfile using
#   docker build -t avera:cuda -f AvERA.cuda.dockerfile .
# Run it using
#   docker run --rm -it --gpus all --user "$(id -u):$(id -g)" -v "$PWD:/work" avera:cuda

############################
# Build stage
############################
FROM nvidia/cuda:12.4.1-devel-ubuntu22.04 AS build

ARG DEBIAN_FRONTEND=noninteractive
ARG BOOST_VER=1.90.0
ARG GSL_VER=2.8
ARG CGAL_VER=6.1.1
ARG VORO_VER=0.4.6

# NOTE: Here we use HTTPS cloning as SSH keys are usually not available in Docker
ARG DTFE_REPO=https://github.com/MariusCautun/DTFE.git
ARG DTFE_REF=master

ARG AVERA_REPO=https://github.com/eltevo/avera.git
ARG AVERA_REF=master

WORKDIR /downloads

# Toolchain + deps needed to build Boost/GSL/CGAL/Voro++/DTFE
# CGAL needs GMP/MPFR at build time.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    bash \
    cmake \
    curl \
    git \
    xz-utils \
    pkg-config \
    autoconf automake libtool m4 \
    libgmp-dev \
    libmpfr-dev \
    && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Fetch sources
RUN set -eux; \
    curl -fsSLO "https://archives.boost.io/release/${BOOST_VER}/source/boost_${BOOST_VER//./_}.tar.gz"; \
    tar -xzf "boost_${BOOST_VER//./_}.tar.gz"; \
    curl -fsSLO "https://mirror.ibcp.fr/pub/gnu/gsl/gsl-${GSL_VER}.tar.gz"; \
    tar -xzf "gsl-${GSL_VER}.tar.gz"; \
    curl -fsSL -o "CGAL-${CGAL_VER}-library.tar.xz" "https://github.com/CGAL/cgal/releases/download/v${CGAL_VER}/CGAL-${CGAL_VER}-library.tar.xz"; \
    tar -xJf "CGAL-${CGAL_VER}-library.tar.xz"; \
    curl -fsSLO "https://math.lbl.gov/voro++/download/dir/voro++-${VORO_VER}.tar.gz"; \
    tar -xzf "voro++-${VORO_VER}.tar.gz"

# BOOST (shared libs, minimal set)
RUN set -eux; \
    cd "/downloads/boost_${BOOST_VER//./_}"; \
    ./bootstrap.sh --prefix=/opt/boost; \
    ./b2 -j"$(nproc)" install \
      --with-system --with-thread --with-filesystem --with-program_options \
      link=shared runtime-link=shared

# GSL
RUN set -eux; \
    cd "/downloads/gsl-${GSL_VER}"; \
    ./configure --prefix=/opt/gsl; \
    make -j"$(nproc)"; \
    make install

# CGAL
# (will find GMP/MPFR from system and uses headers mostly,
# but installs cmake config + any built artifacts under /opt/cgal)
RUN set -eux; \
    cd "/downloads/CGAL-${CGAL_VER}"; \
    cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/cgal; \
    cmake --build build -j"$(nproc)"; \
    cmake --install build

# Voro++
RUN set -eux; \
    cd "/downloads/voro++-${VORO_VER}"; \
    sed -i 's|^PREFIX *=.*|PREFIX=/opt/voro++|' config.mk; \
    make -j"$(nproc)"; \
    make install

# DTFE
WORKDIR /opt
RUN set -eux; \
    git clone "${DTFE_REPO}" dtfe; \
    cd dtfe; \
    git checkout "${DTFE_REF}"

# Makefile edits (best-effort, avoids interactive editing)
# - set paths
# - disable HDF5_PATH and MPFR_PATH lines if present
# - enable DOUBLE option if present/commented
# - add deprecated boost timer define
# - remove -lboost_system and -lCGAL from link lines
# Thank all regex commands to ChatGPT
RUN set -eux; \
    cd /opt/dtfe; \
    if [ -f Makefile ]; then \
      sed -i \
        -e 's|^[#[:space:]]*GSL_PATH[[:space:]]*=.*|GSL_PATH = /opt/gsl|g' \
        -e 's|^[#[:space:]]*BOOST_PATH[[:space:]]*=.*|BOOST_PATH = /opt/boost|g' \
        -e 's|^[#[:space:]]*CGAL_PATH[[:space:]]*=.*|CGAL_PATH = /opt/cgal|g' \
        -e 's|^[[:space:]]*HDF5_PATH[[:space:]]*=.*|# HDF5_PATH disabled in container|g' \
        -e 's|^[[:space:]]*MPFR_PATH[[:space:]]*=.*|# MPFR_PATH disabled in container|g' \
        Makefile || true; \
      # Uncomment or add DOUBLE define
      if grep -qE '^[#[:space:]]*OPTIONS[[:space:]]*\+=.*-DDOUBLE' Makefile; then \
        sed -i 's|^[#[:space:]]*OPTIONS[[:space:]]*\+=.*-DDOUBLE|OPTIONS += -DDOUBLE|' Makefile; \
      else \
        echo 'OPTIONS += -DDOUBLE' >> Makefile; \
      fi; \
      # Add deprecated timer define
      if ! grep -q 'BOOST_TIMER_ENABLE_DEPRECATED' Makefile; then \
        echo 'OPTIONS += -DBOOST_TIMER_ENABLE_DEPRECATED' >> Makefile; \
      fi; \
      # Remove link flags if present
      sed -i 's/-lboost_system//g; s/-lCGAL//g' Makefile || true; \
    fi

ENV CPPFLAGS="-I/opt/boost/include -I/opt/gsl/include -I/opt/cgal/include -I/opt/voro++/include"
ENV LDFLAGS="-L/opt/boost/lib -L/opt/gsl/lib -L/opt/voro++/lib -L/opt/cgal/lib"
ENV LD_LIBRARY_PATH="/opt/boost/lib:/opt/gsl/lib:/opt/voro++/lib:/opt/cgal/lib"
RUN set -eux; \
    cd /opt/dtfe; \
    mkdir -p DTFE_include DTFE_include/CGAL_triangulation DTFE_lib; \
    make -j"$(nproc)" library \
      INC_DIR=/opt/dtfe/DTFE_include \
      LIB_DIR=/opt/dtfe/DTFE_lib

RUN set -eux; \
    cd /opt/dtfe; \
    [ -d DTFE_include ] && ln -sfn "/opt/dtfe/DTFE_include" /opt/dtfe/include || true; \
    [ -d DTFE_lib ]     && ln -sfn "/opt/dtfe/DTFE_lib"     /opt/dtfe/lib     || true

# AvERA
WORKDIR /avera
RUN set -eux; \
    git clone "${AVERA_REPO}" /avera; \
    cd /avera; \
    git checkout "${AVERA_REF}"

# Patch AvERA Makefile
RUN set -eux; \
    cd /avera; \
    if [ -f Makefile ]; then \
      sed -i \
        -e 's|^VORO=.*|VORO=/opt/voro++/include/voro++|g' \
        -e 's|^DTFE=.*|DTFE=/opt/dtfe|g' \
        -e 's|^E_LIB=.*|E_LIB=-L/opt/voro++/lib|g' \
        -e 's|^D_LIB=.*|D_LIB=-L/opt/dtfe/DTFE_lib|g' \
        -e 's|^USING_CUDA=.*|USING_CUDA=YES|g' \
        -e 's|^CUDA_PATH=.*|CUDA_PATH=/usr/local/cuda|g' \
        Makefile || true; \
      # Ensure runtime search path for DTFE + Voro++ (and make it deterministic)
      if ! grep -q 'Wl,-rpath,/opt/dtfe/DTFE_lib' Makefile; then \
        sed -i 's|^LDFLAGS[[:space:]]*\+=.*|LDFLAGS += $(D_LIB) -Wl,-rpath,/opt/dtfe/DTFE_lib -Wl,-rpath,/opt/voro++/lib|g' Makefile; \
      fi; \
    fi

# Link Boost into DTFE so AvERA sees it (hack)
RUN set -eux; \
    ln -sfn /opt/boost/include/boost /opt/dtfe/DTFE_include/boost

ENV LD_LIBRARY_PATH="/opt/boost/lib:/opt/gsl/lib:/opt/voro++/lib:/opt/cgal/lib:/opt/dtfe/DTFE_lib"
RUN set -eux; \
    cd /avera; \
    make -j"$(nproc)" \
      CPPFLAGS="-I/opt/boost/include -I/opt/gsl/include -I/opt/cgal/include -I/opt/voro++/include -I/opt/voro++/include/voro++ -I/opt/dtfe/DTFE_include" \
      LDFLAGS="-L/opt/boost/lib -L/opt/gsl/lib -L/opt/cgal/lib -L/opt/voro++/lib -L/opt/dtfe/DTFE_lib -Wl,-rpath,/opt/dtfe/DTFE_lib -Wl,-rpath,/opt/voro++/lib"


############################
# Runtime stage
############################
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04 AS runtime


ARG DEBIAN_FRONTEND=noninteractive
ARG UID=1000
ARG GID=1000

RUN groupadd -g ${GID} avera \
     && useradd -m -u ${UID} -g ${GID} -s /bin/bash avera

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libstdc++6 \
    libgcc-s1 \
    libgomp1 \
    libgmp10 \
    libmpfr6 \
    openmpi-bin \
    libopenmpi3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /opt/boost /opt/boost
COPY --from=build /opt/gsl /opt/gsl
COPY --from=build /opt/cgal /opt/cgal
COPY --from=build /opt/voro++ /opt/voro++
COPY --from=build /opt/dtfe /opt/dtfe

COPY --from=build /avera/CCLEA_CUDA /usr/local/bin/avera

ENV LD_LIBRARY_PATH="/opt/boost/lib:/opt/gsl/lib:/opt/voro++/lib:/opt/cgal/lib:/opt/dtfe/DTFE_lib"

WORKDIR /work
CMD ["/bin/bash"]