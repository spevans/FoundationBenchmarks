# Run using: docker build --tag=foundation-benchmark-tests:$(date +%s) .
FROM swift:5.2

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && apt-get -q install -y libsqlite3-dev

COPY . /root/
WORKDIR /root
RUN swift run -c release
