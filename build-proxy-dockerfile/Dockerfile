FROM centos:7

ADD openshift-istio-bazel.repo /etc/yum.repos.d/openshift-istio-bazel.repo

RUN yum install -y centos-release-scl epel-release \
 && yum install -y git \
                   wget \
                   devtoolset-4-gcc \
                   devtoolset-4-gcc-c++ \
                   devtoolset-4-libatomic-devel \
                   devtoolset-4-libstdc++-devel \
                   devtoolset-4-runtime \
                   cmake3 \
                   make \
                   bazel \
                   libtool \
                   patch \
                   ksh \
 && yum clean all

ENV FETCH_DIR=/istio-proxy/FETCH \
    CENTOS=true \
    CREATE_TARBALL=true

ADD istio-proxy /istio-proxy

WORKDIR /istio-proxy
