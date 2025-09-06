#!/usr/bin/env bash
set -euo pipefail

# Script: install_google_cloud_cpp.sh
# Installs google-cloud-cpp v2.30.0 from source into /usr/local
# https://github.com/googleapis/google-cloud-cpp/blob/v2.30.x/doc/packaging.md

VERSION="v2.30.0"
PREFIX="/usr/local"

echo "=== 1) Install prerequisites ==="
sudo apt update
sudo apt --no-install-recommends install -y apt-transport-https apt-utils \
        automake build-essential cmake ca-certificates curl git \
        gcc g++ libc-ares-dev libc-ares2 libcurl4-openssl-dev \
        libssl-dev m4 make pkg-config tar wget zlib1g-dev libre2-dev



# Abseil
mkdir -p /tmp/abseil-cpp && cd /tmp/abseil-cpp
curl -fsSL https://github.com/abseil/abseil-cpp/archive/20240722.0.tar.gz | \
    tar -xzf - --strip-components=1 && \
    cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DABSL_BUILD_TESTING=OFF \
      -DABSL_PROPAGATE_CXX_STD=ON \
      -DBUILD_SHARED_LIBS=yes \
      -S . -B cmake-out && \
    cmake --build cmake-out -- -j ${NCPU:-4} && \
sudo cmake --build cmake-out --target install -- -j ${NCPU:-4} && \
sudo ldconfig

# Protobuf
mkdir -p /tmp/protobuf && cd /tmp/protobuf
curl -fsSL https://github.com/protocolbuffers/protobuf/archive/v28.2.tar.gz | \
    tar -xzf - --strip-components=1 && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=yes \
        -Dprotobuf_BUILD_TESTS=OFF \
        -Dprotobuf_ABSL_PROVIDER=package \
        -S . -B cmake-out && \
    cmake --build cmake-out -- -j ${NCPU:-4} && \
sudo cmake --build cmake-out --target install -- -j ${NCPU:-4} && \
sudo ldconfig

# gRPC
mkdir -p /tmp/grpc && cd /tmp/grpc
curl -fsSL https://github.com/grpc/grpc/archive/v1.66.1.tar.gz | \
    tar -xzf - --strip-components=1 && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=yes \
        -DgRPC_INSTALL=ON \
        -DgRPC_BUILD_TESTS=OFF \
        -DgRPC_ABSL_PROVIDER=package \
        -DgRPC_CARES_PROVIDER=package \
        -DgRPC_PROTOBUF_PROVIDER=package \
        -DgRPC_RE2_PROVIDER=package \
        -DgRPC_SSL_PROVIDER=package \
        -DgRPC_ZLIB_PROVIDER=package \
        -S . -B cmake-out && \
    cmake --build cmake-out -- -j ${NCPU:-4} && \
sudo cmake --build cmake-out --target install -- -j ${NCPU:-4} && \
sudo ldconfig

#crc32c
mkdir -p /tmp/crc32c && cd /tmp/crc32c
curl -fsSL https://github.com/google/crc32c/archive/1.1.2.tar.gz | \
    tar -xzf - --strip-components=1 && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=yes \
        -DCRC32C_BUILD_TESTS=OFF \
        -DCRC32C_BUILD_BENCHMARKS=OFF \
        -DCRC32C_USE_GLOG=OFF \
        -S . -B cmake-out && \
    cmake --build cmake-out -- -j ${NCPU:-4} && \
sudo cmake --build cmake-out --target install -- -j ${NCPU:-4} && \
sudo ldconfig

# nlohmann_json
mkdir -p /tmp/json && cd /tmp/json
curl -fsSL https://github.com/nlohmann/json/archive/v3.11.3.tar.gz | \
    tar -xzf - --strip-components=1 && \
    cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=yes \
      -DBUILD_TESTING=OFF \
      -DJSON_BuildTests=OFF \
      -S . -B cmake-out && \
    cmake --build cmake-out -- -j ${NCPU:-4} && \
sudo cmake --build cmake-out --target install -- -j ${NCPU:-4} && \
sudo ldconfig

# opentelemetry-cpp
mkdir -p /tmp/opentelemetry-cpp && cd /tmp/opentelemetry-cpp
curl -fsSL https://github.com/open-telemetry/opentelemetry-cpp/archive/v1.16.1.tar.gz | \
    tar -xzf - --strip-components=1 && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=yes \
        -DWITH_EXAMPLES=OFF \
        -DWITH_ABSEIL=ON \
        -DBUILD_TESTING=OFF \
        -DOPENTELEMETRY_INSTALL=ON \
        -DOPENTELEMETRY_ABI_VERSION_NO=2 \
        -DWITH_DEPRECATED_SDK_FACTORY=OFF \
        -S . -B cmake-out && \
    cmake --build cmake-out -- -j ${NCPU:-4} && \
sudo cmake --build cmake-out --target install -- -j ${NCPU:-4} && \
sudo ldconfig

# Compile and install the main project
echo "=== 2) Build and install google-cloud-cpp ${VERSION} ==="
mkdir -p /tmp/google-cloud-cpp && cd /tmp/google-cloud-cpp
curl -fsSL "https://github.com/googleapis/google-cloud-cpp/archive/refs/tags/${VERSION}.tar.gz" \
  | tar -xzf - --strip-components=1

# Ensure CMake and pkg-config can find deps installed in /usr/local
export CMAKE_PREFIX_PATH="/usr/local"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig"

# Optional: quick sanity check (won't stop the script if missing)
ls -1 /usr/local/lib/cmake/grpc/gRPCConfig.cmake /usr/local/lib/libgrpc++.so || true

cmake -S . -B cmake-out \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DBUILD_TESTING=OFF \
  -DGOOGLE_CLOUD_CPP_WITH_MOCKS=OFF \
  -DGOOGLE_CLOUD_CPP_ENABLE_EXAMPLES=OFF \
  -DGOOGLE_CLOUD_CPP_ENABLE=vision,storage,pubsub,opentelemetry \
  -DGOOGLE_CLOUD_CPP_EXTERNAL_DEPENDENCIES=abseil

cmake --build cmake-out -- -j"$(nproc)"
sudo cmake --install cmake-out
sudo ldconfig

echo "=== Done. google-cloud-cpp ${VERSION} installed to ${PREFIX} ==="
