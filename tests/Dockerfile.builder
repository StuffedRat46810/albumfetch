FROM alpine:latest

RUN apk add --no-cache curl xz jq tar

# Copy the version file from your project root into the container
COPY .zig-version /tmp/.zig-version

# Read the file into a variable, then use it in the jq query
RUN ZIG_VER=$(cat /tmp/.zig-version) && \
    ZIG_URL=$(curl -s https://ziglang.org/download/index.json | jq -r ".[\"$ZIG_VER\"][\"x86_64-linux\"][\"tarball\"]") && \
    mkdir -p /usr/local/zig && \
    curl -o /tmp/zig.tar.xz $ZIG_URL && \
    tar -xf /tmp/zig.tar.xz -C /usr/local/zig --strip-components=1 && \
    rm /tmp/zig.tar.xz

ENV PATH="/usr/local/zig:${PATH}"
