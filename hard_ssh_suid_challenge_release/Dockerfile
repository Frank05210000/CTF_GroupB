FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
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
