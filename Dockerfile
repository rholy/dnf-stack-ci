# Example Usage:
# $ podman build --build-arg TYPE=distro -t ci-dnf-stack -f Dockerfile
# $ podman run --net none -it ci-dnf-stack behave dnf

ARG BASE=fedora:33
FROM $BASE

ENV LANG C.UTF-8
ARG TYPE=nightly

# disable deltas and weak deps
RUN set -x && \
    echo -e "deltarpm=0" >> /etc/dnf/dnf.conf && \
    echo -e "install_weak_deps=0" >> /etc/dnf/dnf.conf

# enable the test-utils repo
RUN set -x && \
    dnf -y install dnf-plugins-core; \
    dnf -y copr enable rpmsoftwaremanagement/test-utils;

# enable nightlies if requested
RUN set -x && \
    if [ "$TYPE" == "nightly" ]; then \
        dnf -y copr enable rpmsoftwaremanagement/dnf-nightly; \
    fi

# upgrade all packages
RUN set -x && \
    dnf -y --refresh upgrade

# copy test suite
COPY ./dnf-behave-tests/ /opt/ci/dnf-behave-tests

# install test suite dependencies
RUN set -x && \
    dnf -y builddep /opt/ci/dnf-behave-tests/requirements.spec && \
    pip3 install -r /opt/ci/dnf-behave-tests/requirements.txt

# install local RPMs if available
COPY ./rpms/ /opt/ci/rpms/
RUN rm /opt/ci/rpms/*-{devel,debuginfo,debugsource}*.rpm; \
    if [ -n "$(find /opt/ci/rpms/ -maxdepth 1 -name '*.rpm' -print -quit)" ]; then \
        dnf -y install /opt/ci/rpms/*.rpm --disableplugin=local; \
    fi

RUN set -x && \
    rm -rf "/opt/ci/dnf-behave-tests/fixtures/certificates/testcerts/" && \
    rm -rf "/opt/ci/dnf-behave-tests/fixtures/gpgkeys/keys/" && \
    rm -rf "/opt/ci/dnf-behave-tests/fixtures/repos/"

# build test repos from sources
RUN set -x && \
    cd /opt/ci/dnf-behave-tests/fixtures/specs/ && \
    ./build.sh --force-rebuild

WORKDIR /opt/ci/dnf-behave-tests
