FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/partial/* \
    && sed -i 's|http://ports.ubuntu.com/ubuntu-ports|https://ports.ubuntu.com/ubuntu-ports|g' /etc/apt/sources.list \
    && apt-get -o Acquire::Retries=5 -o Acquire::https::Verify-Peer=false update \
    && apt-get -o Acquire::Retries=5 -o Acquire::https::Verify-Peer=false install -y --no-install-recommends ca-certificates \
    && apt-get -o Acquire::Retries=5 update \
    && apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
        openssh-server \
        vim-nox \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash user \
    && echo "user:password123" | chpasswd \
    && mkdir -p /run/sshd \
    && sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?KbdInteractiveAuthentication .*/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?UsePAM .*/UsePAM yes/' /etc/ssh/sshd_config \
    && printf '\nAllowUsers user\nLogLevel VERBOSE\n' >> /etc/ssh/sshd_config

RUN echo "FLAG{suid_vim_rooted}" > /root/flag.txt \
    && chmod 600 /root/flag.txt \
    && chown root:root /root/flag.txt \
    && echo "The answer is not here. Look for unusual permissions." > /home/user/hint.txt \
    && chown user:user /home/user/hint.txt

RUN real_vim="$(readlink -f /usr/bin/vim)" \
    && rm -f /usr/bin/vim \
    && install -o root -g root -m 4755 "$real_vim" /usr/bin/vim \
    && /usr/bin/vim --version | grep -q '+python3' \
    && /usr/sbin/sshd -t

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

EXPOSE 22

CMD ["/entrypoint.sh"]
