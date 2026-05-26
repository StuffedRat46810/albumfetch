FROM alpine:latest

RUN apk add --no-cache curl xz jq tar

# Docker will run this once, cache the result, and never download it again 
# unless you change the version number in this file.
RUN ZIG_URL=$(curl -s https://ziglang.org/download/index.json | jq -r '.["0.16.0"]["x86_64-linux"]["tarball"]') && \
    mkdir -p /usr/local/zig && \
    curl -o /tmp/zig.tar.xz $ZIG_URL && \
    tar -xf /tmp/zig.tar.xz -C /usr/local/zig --strip-components=1 && \
    rm /tmp/zig.tar.xz

# Add Zig to the system path so we can call it cleanly
ENV PATH="/usr/local/zig:${PATH}"
