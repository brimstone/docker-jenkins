FROM docker:dind

ENTRYPOINT ["/entrypoint"]

EXPOSE 22

RUN apk -U add openssh openjdk8-jre bash git \
 && addgroup docker \
 && adduser -h "/home/jenkins" -u 1000 -s /bin/sh -D jenkins -G docker \
 && echo "jenkins:jenkins" | chpasswd \
 && echo "PermitEmptyPasswords yes" >> /etc/ssh/sshd_config \
 && ln -s /usr/local/bin/docker /usr/bin/docker

COPY entrypoint /entrypoint
