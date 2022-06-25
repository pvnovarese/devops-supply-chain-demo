FROM xmrig/xmrig:latest AS xmrig

FROM registry.access.redhat.com/ubi8:latest

LABEL maintainer="pvn@novarese.net"
LABEL name="DevOps-Supply-Chain-Demo"
LABEL org.opencontainers.image.title="DevOps-Supply-Chain-Demo"
LABEL org.opencontainers.image.description="Simple image to test policy rules with Anchore Enterprise and GitHub CI workflow."

# define healthcheck
HEALTHCHECK --timeout=10s CMD /bin/true || exit 1

## if you need to use the actual rpm rather than the hints file, use this COPY and comment out the other one
## and don't forget to actually yum install it as well.
##COPY Dockerfile sudo-1.8.29-5.el8.x86_64.rpm ./
COPY Dockerfile anchore_hints.json log4j-core-2.14.1.jar /
COPY ./pom.xml /workdir/pom.xml

# install cryptominer
COPY --from=xmrig /xmrig/xmrig /xmrig/xmrig

RUN set -ex && \
    adduser -d /xmrig mining && \
    echo "--BEGIN PRIVATE KEY--" > /private_key && \
    echo "aws_access_key_id=01234567890123456789" > /aws_key && \
    dnf -y install ruby python3-devel python3 python3-pip java-11-openjdk maven nodejs tar gzip && \
    curl https://anchorectl-releases.s3-us-west-2.amazonaws.com/v0.2.0/anchorectl_0.2.0_linux_amd64.tar.gz | tar xzvf - -C /usr/local/bin/ && \
    python3 -m ensurepip && \
    pip3 install --index-url https://pypi.org/simple --no-cache-dir aiohttp==3.7.3 pytest urllib3 botocore six numpy && \
    gem install bundler lockbox:0.6.8 ftpd:0.2.1 && \
    npm install --cache /tmp/empty-cache debug chalk commander xmldom@0.4.0 && \
    npm cache clean --force && \
    mvn clean install && mvn package && \
    dnf remove ruby python3-devel python3-pip python3 java-11-openjdk maven nodejs epel-release -y && \
    dnf autoremove -y && \
    dnf clean all && \
    rm -rf /var/cache/yum /tmp

# this is here to test rules to detect ADD and to trigger rules looking for 
# pulling code from arbitrary public repos
ADD https://github.com/kevinboone/solunar_cmdline.git /solunar_cmdline

## just to make sure we have a unique build each time
RUN date > /image_build_timestamp

USER mining
WORKDIR /xmrig
ENTRYPOINT /bin/false
