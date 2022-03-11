FROM debian:buster
LABEL maintainer="darexsu"
ARG DEBIAN_FRONTEND=noninteractive
ENV pip_packages "ansible cryptography"
ENV ANSIBLE_USER=ansible SUDO_GROUP=sudo DEPLOY_GROUP=deployer

RUN apt-get update \
    && apt-get install -y \    
        systemd systemd-sysv \
        python3-pip python3-dev python3-setuptools python3-wheel python3-apt \
        sudo build-essential libffi-dev libssl-dev \
        net-tools iproute2 wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && rm -f /lib/systemd/system/multi-user.target.wants/* \
             /etc/systemd/system/*.wants/* \
             /lib/systemd/system/local-fs.target.wants/* \
             /lib/systemd/system/sockets.target.wants/*udev* \
             /lib/systemd/system/sockets.target.wants/*initctl* \
             /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
             /lib/systemd/system/systemd-update-utmp*

# Upgrade pip to latest version.
RUN pip3 install --upgrade pip

# Install Ansible via pip.
RUN pip3 install $pip_packages

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN echo "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts

# Make sure systemd doesn't start agettys on tty[1-6].
RUN rm -f /lib/systemd/system/multi-user.target.wants/getty.target

RUN set -xe \
  && groupadd -r ${ANSIBLE_USER} \
  && groupadd -r ${DEPLOY_GROUP} \
  && useradd -m -g ${ANSIBLE_USER} ${ANSIBLE_USER} \
  && usermod -aG ${SUDO_GROUP} ${ANSIBLE_USER} \
  && usermod -aG ${DEPLOY_GROUP} ${ANSIBLE_USER} \
  && sed -i "/^%${SUDO_GROUP}/s/ALL\$/NOPASSWD:ALL/g" /etc/sudoers

VOLUME ["/sys/fs/cgroup"]
CMD ["/lib/systemd/systemd"]
