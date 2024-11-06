ARG GOLANG_VERSION=1.22.5
ARG CMAKE_VERSION=3.29.6
ARG CUDA_VERSION=12.6.0

# Copy the minimal context we need to run the generate scripts
FROM scratch AS llm-code
COPY llm llm

FROM --platform=linux/amd64 nvidia/cuda:12.4.0-devel-centos7 AS cuda-build-amd64
ARG CMAKE_VERSION
COPY ./scripts/rh_linux_deps.sh /
RUN CMAKE_VERSION=${CMAKE_VERSION} sh /rh_linux_deps.sh
ENV PATH /opt/rh/devtoolset-10/root/usr/bin:$PATH
COPY --from=llm-code / /go/src/github.com/ollama/ollama/
WORKDIR /go/src/github.com/ollama/ollama/llm/generate
ARG CGO_CFLAGS
RUN OLLAMA_SKIP_STATIC_GENERATE=1 OLLAMA_SKIP_CPU_GENERATE=1 sh gen_linux.sh

FROM --platform=linux/arm64 nvidia/cuda:$CUDA_VERSION-devel-rockylinux8 AS cuda-build-arm64
ARG CMAKE_VERSION
COPY ./scripts/rh_linux_deps.sh /
RUN CMAKE_VERSION=${CMAKE_VERSION} sh /rh_linux_deps.sh
ENV PATH /opt/rh/gcc-toolset-10/root/usr/bin:$PATH
COPY --from=llm-code / /go/src/github.com/ollama/ollama/
WORKDIR /go/src/github.com/ollama/ollama/llm/generate
ARG CGO_CFLAGS
RUN OLLAMA_SKIP_STATIC_GENERATE=1 OLLAMA_SKIP_CPU_GENERATE=1 sh gen_linux.sh

FROM --platform=linux/amd64 centos:7 AS cpu-builder-amd64
ARG CMAKE_VERSION
ARG GOLANG_VERSION
COPY ./scripts/rh_linux_deps.sh /
RUN CMAKE_VERSION=${CMAKE_VERSION} GOLANG_VERSION=${GOLANG_VERSION} sh /rh_linux_deps.sh
ENV PATH /opt/rh/devtoolset-10/root/usr/bin:$PATH
COPY --from=llm-code / /go/src/github.com/ollama/ollama/
ARG OLLAMA_CUSTOM_CPU_DEFS
ARG CGO_CFLAGS
WORKDIR /go/src/github.com/ollama/ollama/llm/generate

FROM --platform=linux/amd64 cpu-builder-amd64 AS static-build-amd64
RUN OLLAMA_CPU_TARGET="static" sh gen_linux.sh
FROM --platform=linux/amd64 cpu-builder-amd64 AS cpu-build-amd64
RUN OLLAMA_SKIP_STATIC_GENERATE=1 OLLAMA_CPU_TARGET="cpu" sh gen_linux.sh
FROM --platform=linux/amd64 cpu-builder-amd64 AS cpu_avx-build-amd64
RUN OLLAMA_SKIP_STATIC_GENERATE=1 OLLAMA_CPU_TARGET="cpu_avx" sh gen_linux.sh
FROM --platform=linux/amd64 cpu-builder-amd64 AS cpu_avx2-build-amd64
RUN OLLAMA_SKIP_STATIC_GENERATE=1 OLLAMA_CPU_TARGET="cpu_avx2" sh gen_linux.sh

FROM --platform=linux/arm64 rockylinux:8 AS cpu-builder-arm64
ARG CMAKE_VERSION
ARG GOLANG_VERSION
COPY ./scripts/rh_linux_deps.sh /
RUN CMAKE_VERSION=${CMAKE_VERSION} GOLANG_VERSION=${GOLANG_VERSION} sh /rh_linux_deps.sh
ENV PATH /opt/rh/gcc-toolset-10/root/usr/bin:$PATH
COPY --from=llm-code / /go/src/github.com/ollama/ollama/
ARG OLLAMA_CUSTOM_CPU_DEFS
ARG CGO_CFLAGS
WORKDIR /go/src/github.com/ollama/ollama/llm/generate

FROM --platform=linux/arm64 cpu-builder-arm64 AS static-build-arm64
RUN OLLAMA_CPU_TARGET="static" sh gen_linux.sh
FROM --platform=linux/arm64 cpu-builder-arm64 AS cpu-build-arm64
RUN OLLAMA_SKIP_STATIC_GENERATE=1 OLLAMA_CPU_TARGET="cpu" sh gen_linux.sh

# Intermediate stage used for ./scripts/build_linux.sh
FROM --platform=linux/amd64 cpu-build-amd64 AS build-amd64
ENV CGO_ENABLED 1
WORKDIR /go/src/github.com/ollama/ollama
COPY . .
COPY --from=static-build-amd64 /go/src/github.com/ollama/ollama/llm/build/linux/ llm/build/linux/
COPY --from=cpu_avx-build-amd64 /go/src/github.com/ollama/ollama/llm/build/linux/ llm/build/linux/
COPY --from=cpu_avx2-build-amd64 /go/src/github.com/ollama/ollama/llm/build/linux/ llm/build/linux/
COPY --from=cuda-build-amd64 /go/src/github.com/ollama/ollama/llm/build/linux/ llm/build/linux/
ARG GOFLAGS
ARG CGO_CFLAGS
RUN go build -trimpath -o /go/src/github.com/ollama/ollama/rose .

# Intermediate stage used for ./scripts/build_linux.sh
FROM --platform=linux/arm64 cpu-build-arm64 AS build-arm64
ENV CGO_ENABLED 1
ARG GOLANG_VERSION
WORKDIR /go/src/github.com/ollama/ollama
COPY . .
COPY --from=static-build-arm64 /go/src/github.com/ollama/ollama/llm/build/linux/ llm/build/linux/
COPY --from=cuda-build-arm64 /go/src/github.com/ollama/ollama/llm/build/linux/ llm/build/linux/
ARG GOFLAGS
ARG CGO_CFLAGS
RUN go build -trimpath -o /go/src/github.com/ollama/ollama/rose .

# Runtime stages
FROM --platform=linux/amd64 ubuntu:22.04 as runtime-amd64
RUN apt-get update && apt-get install -y ca-certificates
COPY --from=build-amd64 /go/src/github.com/ollama/ollama/rose /bin/rose
FROM --platform=linux/arm64 ubuntu:22.04 as runtime-arm64
RUN apt-get update && apt-get install -y ca-certificates
COPY --from=build-arm64 /go/src/github.com/ollama/ollama/rose /bin/rose

FROM runtime-$TARGETARCH
EXPOSE 11434
ENV ROSE_HOST 0.0.0.0
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV NVIDIA_VISIBLE_DEVICES=all

ENTRYPOINT ["/bin/rose"]
CMD ["serve"]

