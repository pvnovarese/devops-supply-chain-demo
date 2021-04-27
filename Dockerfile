FROM xmrig/xmrig:latest AS build1

FROM anchore/test_images:vulnerabilities-alpine

RUN set -ex && \
    adduser -S -D -h /xmrig mining && \
    echo "aws_access_key_id=01234567890123456789" > /aws_key && \
    apk add --no-cache python3 git && \
    python3 -m ensurepip && \
    pip3 install --index-url https://pypi.org/simple --no-cache-dir pytest && \
    rm -rf /var/cache/apk/*

ADD https://github.com/kevinboone/solunar_cmdline.git /solunar_cmdline
COPY --from=build1 /xmrig/xmrig /xmrig/xmrig
USER mining
WORKDIR /xmrig
ENTRYPOINT /bin/false
