FROM fedora:25
ENV LANG C
ARG type=local

COPY dnf-docker-test/repo /var/www/html/repo/
COPY dnf-docker-test/features /behave/
COPY dnf-docker-test/features /tests/
COPY rpms /rpms/
COPY dnf-docker-test/x509certgen /usr/local/bin

RUN set -x && \
    echo -e "deltarpm=0\ntsflags=nodocs" >> /etc/dnf/dnf.conf && \
    # httpd:      http-style repos
    # vsftpd:     ftp-style repos
    # behave:     core
    # six:        py2/py3
    # enum34:     enum for py2, rpmdb.State
    # whichcraft: shutil.which() for py2
    # jinja2:     rpmspec template
    # pexpect:    shell tests
    # rpm-build:  building dummy RPMs
    dnf -y install httpd vsftpd python2-behave python2-six python-enum34 python2-whichcraft python-jinja2 python2-pexpect rpm-build openssl mod_ssl && \
    if [ $type = "local" ]; then \
        # Allows to run test with rpms from only single component in rpms/
        dnf -y install dnf-plugins-core python3-dnf-plugins-core python2-dnf-plugins-core createrepo_c && \
        dnf -y copr enable rpmsoftwaremanagement/dnf-nightly; \
    fi && \
    # prevent installation of dnf-plugins-extras (versionlock, local, torproxy)
    rm -vf /rpms/*extras-versionlock*.rpm /rpms/*extras-local*.rpm /rpms/*extras-torproxy*.rpm && \
    # update dnf
    dnf -y --best upgrade dnf && \
    if [ $type = "local" ]; then \
        # install all rpms if present
        if ls /rpms/*.rpm 1>/dev/null 2>&1; then dnf -y install /rpms/*.rpm; fi && \
        # workaround for https://bugzilla.redhat.com/show_bug.cgi?id=1398272
        rpm -q dnf && \
        # some unknown thing
        dnf -y mark install $(dnf repoquery --unneeded -q); \
    else \
        dnf -y install /rpms/*.rpm && \
        dnf -y autoremove; \
    fi && \
    # generate certificates that will be used for the testing purposes
    /usr/local/bin/x509certgen x509KeyGen ca && \
    /usr/local/bin/x509certgen x509KeyGen server && \
    /usr/local/bin/x509certgen x509KeyGen client && \
    /usr/local/bin/x509certgen x509KeyGen ca2 && \
    /usr/local/bin/x509certgen x509KeyGen server2 && \
    /usr/local/bin/x509certgen x509KeyGen client2 && \
    /usr/local/bin/x509certgen x509SelfSign ca && \
    /usr/local/bin/x509certgen x509SelfSign ca2 && \
    /usr/local/bin/x509certgen x509CertSign --CA ca server && \
    /usr/local/bin/x509certgen x509CertSign --CA ca client && \
    /usr/local/bin/x509certgen x509CertSign --CA ca2 server2 && \
    /usr/local/bin/x509certgen x509CertSign --CA ca2 client2 && \
    # configure httpd
    sed -i "s/#ServerName .*/ServerName ${HOSTNAME}:80/" /etc/httpd/conf/httpd.conf && \
    sed -i 's:^SSLCertificateFile .*:SSLCertificateFile /etc/pki/tls/certs/testcerts/server/cert.pem:' /etc/httpd/conf.d/ssl.conf && \
    sed -i 's:^SSLCertificateKeyFile .*:SSLCertificateKeyFile /etc/pki/tls/certs/testcerts/server/key.pem:' /etc/httpd/conf.d/ssl.conf && \
    dnf -y clean all && \
    mkdir /tmp/repos.d && mv /etc/yum.repos.d/* /tmp/repos.d/ && \
    mkdir /repo && \
    rm -f /behave/*.feature

ADD dnf-docker-test/launch-test /usr/bin/
ADD dnf-docker-test/report-behave-json /usr/bin/
VOLUME ["/junit"]
