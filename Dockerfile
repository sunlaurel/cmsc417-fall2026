FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  gdb \
  valgrind \
  iproute2 \
  iputils-ping \
  netcat-openbsd \
  curl \
  ca-certificates \
  libssl-dev \
  libev-dev \
  libncurses-dev \
  libyaml-cpp-dev \
  libprotobuf-dev \
  cmake \
  emacs \
  vim \
  tcpdump \
  bison \
  flex \
  tshark \
  iproute2 \
  protobuf-compiler \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["sleep", "infinity"]
