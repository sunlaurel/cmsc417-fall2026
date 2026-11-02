IMAGE_NAME="cmsc417"
CONTAINER_NAME="cmsc417"
PORT_MAPPING="8080:8080"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE="${SCRIPT_DIR}/Dockerfile"

HOST_WORKSPACE="$(pwd)"

image_exists()     { docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; }
container_exists() { docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; }
container_running() {
  [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null)" = "true" ]
}

write_dockerfile() {
  if [ -f "$DOCKERFILE" ]; then
    echo "found Dockerfile"
    return
  fi
  echo "No Dockerfile found; Creating one"
  cat > "$DOCKERFILE" << 'DOCKERFILE_EOF'
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
  protobuf-compiler \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["sleep", "infinity"]
DOCKERFILE_EOF
  echo "Dockerfile written."
}

build_image() {
  write_dockerfile
  echo "Building image '$IMAGE_NAME'..."
  docker build -t "$IMAGE_NAME" -f "$DOCKERFILE" "$SCRIPT_DIR"
}

create_container() {
  echo "Creating container '$CONTAINER_NAME' ..."


  docker create \
    --name "$CONTAINER_NAME" \
    --hostname "$CONTAINER_NAME" \
    --cap-add=NET_RAW \
    --cap-add=NET_ADMIN \
    -p $PORT_MAPPING \
    -v "$HOST_WORKSPACE:/workspace" \
    -w /workspace \
    "$IMAGE_NAME" 

  echo "Mounted host '$HOST_WORKSPACE' -> /workspace"
  echo "Published ports: $PORT_MAPPING"
}

attach_shell() {
  echo "Attaching to '$CONTAINER_NAME'."
  docker exec -it "$CONTAINER_NAME" /bin/bash
}

stop_container() {
  if container_running; then
    docker stop "$CONTAINER_NAME" 
  fi
}

remove_container() {
  if container_exists; then
    stop_container
    echo "Removing '$CONTAINER_NAME' ..."
    docker rm "$CONTAINER_NAME" >/dev/null
  else
    echo "Container '$CONTAINER_NAME' does not exist."
  fi
}

case "${1:-}" in
  --stop)    stop_container; exit 0 ;;
  --rm)      remove_container; exit 0 ;;
  --rebuild) remove_container; build_image; exit 0;;
  "")        ;;
  *)         echo "Unknown option: $1"; echo "Use --rebuild, --stop, or --rm."; exit 1 ;;
esac

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is not installed or not on PATH."
  exit 1
fi

if ! image_exists; then
  build_image
fi

if container_exists; then
  if ! container_running; then
    echo "Starting existing container '$CONTAINER_NAME' ..."
    docker start "$CONTAINER_NAME" >/dev/null
  fi
else
  create_container
  docker start "$CONTAINER_NAME" >/dev/null
fi

attach_shell
