FROM ubuntu:18.04

RUN apt-get update && apt-get install bash-completion apt-transport-https gnupg wget curl vim openssh-client iputils-ping nmap -y \
    && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    && curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.asc.gpg \
    && echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list \
    && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ bionic main" > /etc/apt/sources.list.d/azure-cli.list \
    && apt-get update && apt-get install -y kubectl azure-cli \
    && apt-get clean all

COPY ./bashrc /root/.bashrc

COPY ./acilabs_binaries/* /usr/local/bin/

CMD ["/bin/bash"]