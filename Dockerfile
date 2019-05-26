
ARG BASE_IMAGE="ubuntu:18.04"
FROM ${BASE_IMAGE}

# setting DEBIAN_FRONTEND=noninteractive stops some apt warnings, this is not 
# a real argument, we're (ab)using ARG to get a temporary ENV again.
ARG DEBIAN_FRONTEND=noninteractive

MAINTAINER LIUCHEN

COPY clean-install /usr/local/bin/clean-install
RUN chmod +x /usr/local/bin/clean-install

# Get dependencies
# The base image already has: ssh, apt, snapd
# This is broken down into (each on a line):
# - packages necessary for installing docker
# - packages needed to run services (systemd)
# - packages needed for docker / hyperkube / kubernetes components
# - misc packages (utilities we use in our own tooling)
# Then we cleanup (removing unwanted systemd services)
# Finally we disable kmsg in journald
# https://developers.redhat.com/blog/2014/05/05/running-systemd-within-docker-container/
RUN clean-install \
      apt-transport-https ca-certificates curl software-properties-common gnupg2 lsb-release \
      systemd systemd-sysv libsystemd0 \
      conntrack iptables iproute2 ethtool socat util-linux mount ebtables udev kmod aufs-tools \
      bash rsync golang btrfs-tools libseccomp-dev \
      autoconf automake libtool make g++ unzip wget pkg-config git \
    && find /lib/systemd/system/sysinit.target.wants/ -name "systemd-tmpfiles-setup.service" -delete \
    && rm -f /lib/systemd/system/multi-user.target.wants/* \
    && rm -f /etc/systemd/system/*.wants/* \
    && rm -f /lib/systemd/system/local-fs.target.wants/* \
    && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
    && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
    && rm -f /lib/systemd/system/basic.target.wants/* \
    && echo "ReadKMsg=no" >> /etc/systemd/journald.conf \
    && mkdir -p proto \
    && cd /proto \
    && wget -c https://github.com/google/protobuf/releases/download/v3.5.0/protoc-3.5.0-linux-x86_64.zip \
    && unzip protoc-3.5.0-linux-x86_64.zip -d /usr/local \
    && cd / \
    && rm -rf proto 


# Install containerd

RUN go get github.com/containerd/containerd \
    && go get github.com/opencontainers/runc \
    && cd /root/go/src/github.com/opencontainers/runc \
    && make \
    && make install \
    && cd /root/go/src/github.com/containerd/containerd \
    && make \
    && make install \
    && cd / \
    && rm -rf /root/go/*


RUN mkdir -p /etc/containerd && containerd config default > /etc/containerd/config.toml

# Install CNI binaries to /opt/cni/bin
# TODO(bentheelder): doc why / what here
ARG CNI_VERSION="0.7.5"
ARG CNI_BASE_URL="https://storage.googleapis.com/kubernetes-release/network-plugins/"
RUN export ARCH=$(dpkg --print-architecture) \
    && export CNI_TARBALL="cni-plugins-${ARCH}-v${CNI_VERSION}.tgz" \
    && export CNI_URL="${CNI_BASE_URL}${CNI_TARBALL}" \
    && curl -sSL --retry 5 --output /tmp/cni.tgz "${CNI_URL}" \
    && sha256sum /tmp/cni.tgz \
    && mkdir -p /opt/cni/bin \
    && tar -C /opt/cni/bin -xzf /tmp/cni.tgz \
    && rm -rf /tmp/cni.tgz

# k3s executable file
COPY k3s /bin/k3s

# load coredns and other images 
# RUN mkdir /ktest
# COPY data.tar /ktest/data.tar
# how to run it???

ENV container containerd
# systemd exits on SIGRTMIN+3, not SIGTERM (which re-executes it)
# # https://bugzilla.redhat.com/show_bug.cgi?id=1201657
STOPSIGNAL SIGRTMIN+3
#
# # wrap systemd with our special entrypoint, see pkg/build for how this is built
# # basically this just lets us set up some things before continuing on to systemd
# # while preserving that systemd is PID1
# # for how we leverage this, see pkg/cluster
COPY entrypoint /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint
# # We need systemd to be PID1 to run the various services (docker, kubelet, etc.)
# # NOTE: this is *only* for documentation, the entrypoint is overridden at runtime
ENTRYPOINT [ "/usr/local/bin/entrypoint", "/sbin/init" ]
