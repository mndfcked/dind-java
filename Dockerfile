FROM docker:dind
LABEL maintainer="Baqend <support@baqend.com>"


# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# FROM: https://github.com/AdoptOpenJDK/openjdk-docker/blob/master/11/jdk/alpine/Dockerfile.hotspot.releases.slim
RUN apk --update add --no-cache --virtual .build-deps curl binutils \
    && GLIBC_VER="2.28-r0" \
    && ALPINE_GLIBC_REPO="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" \
    && GCC_LIBS_URL="https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-8.2.1%2B20180831-1-x86_64.pkg.tar.xz" \
    && GCC_LIBS_SHA256=e4b39fb1f5957c5aab5c2ce0c46e03d30426f3b94b9992b009d417ff2d56af4d \
    && ZLIB_URL="https://archive.archlinux.org/packages/z/zlib/zlib-1%3A1.2.9-1-x86_64.pkg.tar.xz" \
    && ZLIB_SHA256=bb0959c08c1735de27abf01440a6f8a17c5c51e61c3b4c707e988c906d3b7f67 \
    && curl -Ls https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -Ls ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-${GLIBC_VER}.apk > /tmp/${GLIBC_VER}.apk \
    && apk add /tmp/${GLIBC_VER}.apk \
    && curl -Ls ${GCC_LIBS_URL} -o /tmp/gcc-libs.tar.xz \
    && echo "${GCC_LIBS_SHA256}  /tmp/gcc-libs.tar.xz" | sha256sum -c - \
    && mkdir /tmp/gcc \
    && tar -xf /tmp/gcc-libs.tar.xz -C /tmp/gcc \
    && mv /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib \
    && strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so* \
    && curl -Ls ${ZLIB_URL} -o /tmp/libz.tar.xz \
    && echo "${ZLIB_SHA256}  /tmp/libz.tar.xz" | sha256sum -c - \
    && mkdir /tmp/libz \
    && tar -xf /tmp/libz.tar.xz -C /tmp/libz \
    && mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib \
    && apk add --no-cache bash git openssh npm \
    && apk del --purge .build-deps \
    && rm -rf /tmp/${GLIBC_VER}.apk /tmp/gcc /tmp/gcc-libs.tar.xz /tmp/libz /tmp/libz.tar.xz /var/cache/apk/*

ENV JAVA_VERSION jdk-11.0.2+7
ENV KUBE_LATEST_VERSION="v1.13.4"
RUN apk add --update ca-certificates \
 && apk add --update -t deps curl \
 && curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
 && chmod +x /usr/local/bin/kubectl \
 && apk del --purge deps \
 && rm /var/cache/apk/*

COPY slim-java* /usr/local/bin/

RUN set -eux; \
    apk add --virtual .fetch-deps curl; \
    ARCH="$(apk --print-arch)"; \
    case "${ARCH}" in \
       ppc64el|ppc64le) \
         ESUM='47340ac8e29cddca21eb9bc932bcbeb81d0707c42cd6c4cc301923a0de521073'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.2%2B7/OpenJDK11U-jdk_ppc64le_linux_hotspot_11.0.2_7.tar.gz'; \
         ;; \
       s390x) \
         ESUM='e99e55cde2e33ce42d5f01e44f3c885e8899afca39a481327e55706e39adc210'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.2%2B7/OpenJDK11U-jdk_s390x_linux_hotspot_11.0.2_7.tar.gz'; \
         ;; \
       amd64|x86_64) \
         ESUM='d89304a971e5186e80b6a48a9415e49583b7a5a9315ba5552d373be7782fc528'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.2%2B7/OpenJDK11U-jdk_x64_linux_hotspot_11.0.2_7.tar.gz'; \
         ;; \
       aarch64|arm64) \
         ESUM='95b14e954f96185d02afda1a3ab146011076a4d97b457c9333556bd5d9263c41'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.2%2B7/OpenJDK11U-jdk_aarch64_linux_hotspot_11.0.2_7.tar.gz'; \
         ;; \
       *) \
         echo "Unsupported arch: ${ARCH}"; \
         exit 1; \
         ;; \
    esac; \
    curl -Lso /tmp/openjdk.tar.gz ${BINARY_URL}; \
    sha256sum /tmp/openjdk.tar.gz; \
    mkdir -p /opt/java/openjdk; \
    cd /opt/java/openjdk; \
    echo "${ESUM}  /tmp/openjdk.tar.gz" | sha256sum -c -; \
    tar -xf /tmp/openjdk.tar.gz; \
    jdir=$(dirname $(dirname $(find /opt/java/openjdk -name javac))); \
    mv ${jdir}/* /opt/java/openjdk; \
    export PATH="/opt/java/openjdk/bin:$PATH"; \
    apk add --virtual .build-deps bash binutils; \
    /usr/local/bin/slim-java.sh /opt/java/openjdk; \
    apk del --purge .build-deps; \
    apk del --purge .fetch-deps; \
    rm -rf /var/cache/apk/*; \
    rm -rf ${jdir} /tmp/openjdk.tar.gz;

ENV JAVA_HOME=/opt/java/openjdk \
    PATH="/opt/java/openjdk/bin:$PATH"
ENV JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport"