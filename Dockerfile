FROM alpine:edge

# Setup packages
RUN printf "http://dl-cdn.alpinelinux.org/alpine/edge/main\nhttp://dl-cdn.alpinelinux.org/alpine/edge/community\nhttp://dl-cdn.alpinelinux.org/alpine/edge/testing\n" > /etc/apk/repositories
RUN apk update
RUN apk add gcc openssl-dev elfutils-dev git gpg make musl-dev flex bison linux-headers perl mtools netpbm netpbm-extras bc diffutils findutils installkernel python3 sed xz gmp-dev mpc1-dev mpfr-dev # Kernel dependencies
RUN apk add doas alpine-sdk # Alpine SDK and build tools
RUN apk add shadow tar umount losetup coreutils sfdisk e2fsprogs dosfstools # Utilities

# Create build user
RUN adduser -D build -G abuild
RUN addgroup build wheel

# Setup abuild for build user
RUN echo "permit nopass keepenv :wheel" > /etc/doas.conf
USER build
RUN abuild-keygen -i -a -n

USER root

# Setup apkcache
# RUN ln -s /app/cache/apkcache /etc/apk/cache

CMD ["/bin/sh", "./build.sh"]
