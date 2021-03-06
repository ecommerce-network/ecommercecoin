# daemon runs in the background
# run something like tail /var/log/ecommercecoind/current to see the status
# be sure to run with volumes, ie:
# docker run -v $(pwd)/ecommercecoind:/var/lib/ecommercecoind -v $(pwd)/wallet:/home/ecommercecoin --rm -ti ecommercecoin:0.2.2
ARG base_image_version=0.10.0
FROM phusion/baseimage:$base_image_version

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.21.2.2/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

ADD https://github.com/just-containers/socklog-overlay/releases/download/v2.1.0-0/socklog-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/socklog-overlay-amd64.tar.gz -C /

ARG METEORCOIN_BRANCH=master
ENV METEORCOIN_BRANCH=${METEORCOIN_BRANCH}

# install build dependencies
# checkout the latest tag
# build and install
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      python-dev \
      gcc-4.9 \
      g++-4.9 \
      git cmake \
      libboost1.58-all-dev && \
    git clone https://github.com/ecommerce-network/ecommercecoin.git /src/ecommercecoin && \
    cd /src/ecommercecoin && \
    git checkout $METEORCOIN_BRANCH && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_CXX_FLAGS="-g0 -Os -fPIC -std=gnu++11" .. && \
    make -j$(nproc) && \
    mkdir -p /usr/local/bin && \
    cp src/EcommerceCoind /usr/local/bin/EcommerceCoind && \
    cp src/walletd /usr/local/bin/walletd && \
    cp src/zedwallet /usr/local/bin/zedwallet && \
    cp src/miner /usr/local/bin/miner && \
    strip /usr/local/bin/EcommerceCoind && \
    strip /usr/local/bin/walletd && \
    strip /usr/local/bin/zedwallet && \
    strip /usr/local/bin/miner && \
    cd / && \
    rm -rf /src/ecommercecoin && \
    apt-get remove -y build-essential python-dev gcc-4.9 g++-4.9 git cmake libboost1.58-all-dev && \
    apt-get autoremove -y && \
    apt-get install -y  \
      libboost-system1.58.0 \
      libboost-filesystem1.58.0 \
      libboost-thread1.58.0 \
      libboost-date-time1.58.0 \
      libboost-chrono1.58.0 \
      libboost-regex1.58.0 \
      libboost-serialization1.58.0 \
      libboost-program-options1.58.0 \
      libicu55

# setup the ecommercecoind service
RUN useradd -r -s /usr/sbin/nologin -m -d /var/lib/ecommercecoind ecommercecoind && \
    useradd -s /bin/bash -m -d /home/ecommercecoin ecommercecoin && \
    mkdir -p /etc/services.d/ecommercecoind/log && \
    mkdir -p /var/log/ecommercecoind && \
    echo "#!/usr/bin/execlineb" > /etc/services.d/ecommercecoind/run && \
    echo "fdmove -c 2 1" >> /etc/services.d/ecommercecoind/run && \
    echo "cd /var/lib/ecommercecoind" >> /etc/services.d/ecommercecoind/run && \
    echo "export HOME /var/lib/ecommercecoind" >> /etc/services.d/ecommercecoind/run && \
    echo "s6-setuidgid ecommercecoind /usr/local/bin/EcommerceCoind" >> /etc/services.d/ecommercecoind/run && \
    chmod +x /etc/services.d/ecommercecoind/run && \
    chown nobody:nogroup /var/log/ecommercecoind && \
    echo "#!/usr/bin/execlineb" > /etc/services.d/ecommercecoind/log/run && \
    echo "s6-setuidgid nobody" >> /etc/services.d/ecommercecoind/log/run && \
    echo "s6-log -bp -- n20 s1000000 /var/log/ecommercecoind" >> /etc/services.d/ecommercecoind/log/run && \
    chmod +x /etc/services.d/ecommercecoind/log/run && \
    echo "/var/lib/ecommercecoind true ecommercecoind 0644 0755" > /etc/fix-attrs.d/ecommercecoind-home && \
    echo "/home/ecommercecoin true ecommercecoin 0644 0755" > /etc/fix-attrs.d/ecommercecoin-home && \
    echo "/var/log/ecommercecoind true nobody 0644 0755" > /etc/fix-attrs.d/ecommercecoind-logs

VOLUME ["/var/lib/ecommercecoind", "/home/ecommercecoin","/var/log/ecommercecoind"]

ENTRYPOINT ["/init"]
CMD ["/usr/bin/execlineb", "-P", "-c", "emptyenv cd /home/ecommercecoin export HOME /home/ecommercecoin s6-setuidgid ecommercecoin /bin/bash"]
