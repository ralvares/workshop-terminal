FROM registry.access.redhat.com/ubi8

USER root

RUN HOME=/root && \
rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \

INSTALL_PKGS="unzip podman skopeo git cargo nano npm python3-devel openssl-devel python3-pip python3-cryptography python3-mod_wsgi python3-wheel python3-setuptools bash-completion jq libffi-devel libtool-ltdl httpd mod_ssl mod_session supervisor bc java-1.8.0-openjdk java-1.8.0-openjdk-devel" && \
dnf module reset nodejs -y && \
dnf module install nodejs:14 -y && \
yum update -y && yum -y --setopt=tsflags=nodocs install $INSTALL_PKGS && \
yum -y clean all --enablerepo='*'

# Install OpenShift clients.

RUN curl -s -o /tmp/oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz && \
    tar -C /usr/local/bin -zxf /tmp/oc.tar.gz oc && \
    chmod +x /usr/local/bin/oc && \
    rm /tmp/oc.tar.gz

# Install Odo clients

RUN curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/odo/latest/odo-linux-amd64 -o /usr/local/bin/odo && \
    chmod +x /usr/local/bin/odo

# Install Kubernetes client.

RUN curl -sL -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl

# install roxctl - RHACS

RUN curl -sL -o /usr/local/bin/roxctl https://mirror.openshift.com/pub/rhacs/assets/latest/bin/Linux/roxctl && \
    chmod +x /usr/local/bin/roxctl
    
# Common environment variables.

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=off

RUN REMOVE_PKGS="cargo python3-devel openssl-devel libffi-devel libtool-ltdl java-1.8.0-openjdk-devel gcc rust" && pip3 install jmespath openshift ansible setuptools-rust butterfly && dnf remove -y $REMOVE_PKGS

COPY butterfly /opt/workshop/butterfly

RUN HOME=/opt/workshop/butterfly && \
    cd /opt/workshop/butterfly && \
    /opt/workshop/butterfly/install-fonts.sh && \
    /opt/workshop/butterfly/fixup-styles.sh

COPY gateway /opt/workshop/gateway

RUN HOME=/opt/workshop/gateway && \
    cd /opt/workshop/gateway && \
    npm install --production && \
    chown -R 1001:0 /opt/workshop/gateway/node_modules 

# Finish environment setup.

ENV BASH_ENV=/opt/workshop/etc/profile \
    ENV=/opt/workshop/etc/profile \
    PROMPT_COMMAND=". /opt/workshop/etc/profile"

COPY s2i/. /usr/libexec/s2i/

COPY bin/. /usr/local/bin
COPY etc/. /opt/workshop/etc/

COPY bin/start-singleuser.sh /opt/app-root/bin/

RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    chmod g+w /etc/passwd

RUN sed -i.bak -e 's/driver = "overlay"/driver = "vfs"/' \
      /etc/containers/storage.conf

RUN sed -i.bak \
      -e "/\[registries.search\]/{N;s/registries = \[.*\]/registries = ['docker.io', 'registry.fedoraproject.org', 'quay.io', 'registry.centos.org']/}" \
      -e "/\[registries.insecure\]/{N;s/registries = \[.*\]/registries = ['docker-registry.default.svc:5000','image-registry.openshift-image-registry.svc:5000']/}" \
      /etc/containers/registries.conf

COPY containers/libpod.conf /etc/containers/

RUN mkdir -p /opt/app-root/etc/init.d && \
    mkdir -p /opt/app-root/etc/profile.d && \
    mkdir -p /opt/app-root/etc/supervisor && \
    mkdir -p /opt/app-root/gateway/routes && \
    chown -R 1001:0 /opt/app-root && \
    fix-permissions /opt/app-root

COPY .bash_profile /opt/app-root/src/.bash_profile

RUN chown -R 1001:0 /opt/app-root && \
    fix-permissions /opt/app-root -P

RUN cp -rf /opt/workshop/etc/supervisord.conf /etc/supervisord.conf && cat /opt/workshop/etc/profile >> /etc/profile

LABEL io.k8s.display-name="Terminal" \
      io.openshift.expose-services="10080:http" \
      io.openshift.tags="builder,butterfly" \
      io.openshift.s2i.scripts-url=image:///usr/libexec/s2i

EXPOSE 10080

USER 1001

WORKDIR /opt/app-root

CMD [ "/usr/libexec/s2i/run" ]
