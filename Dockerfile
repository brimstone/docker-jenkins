FROM docker:dind

EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--", "/bin/jenkins"]

# tini
RUN apk add --update \
    --repository http://dl-1.alpinelinux.org/alpine/edge/testing/ \
    --repository http://dl-1.alpinelinux.org/alpine/edge/community/ \
    tini openjdk8-jre ttf-dejavu git bash \
 && rm -rf /var/cache/apk/*

# jenkins
ENV JENKINS_UC=https://updates.jenkins-ci.org

ENV JENKINS_HOME=/var/jenkins_home

RUN adduser -h "$JENKINS_HOME" -u 1000 -s /bin/sh -D jenkins

RUN mkdir -p /usr/share/jenkins/ref \
 && curl -fL \
    http://mirrors.jenkins-ci.org/war-stable/latest/jenkins.war \
    -o /usr/share/jenkins/jenkins.war \
 && chown -R jenkins: /usr/share/jenkins

COPY jenkins /bin/

COPY jenkins-cli /bin/

# site specific stuff
USER jenkins

WORKDIR /var/jenkins_home

#VOLUME /var/jenkins_home

RUN /bin/jenkins 2>&1 | tee /tmp/jenkins.log \
  & printf "\n\nWaiting for jenkins to initialize\n" \
 && sleep 1; tail -f /tmp/jenkins.log | grep -qm 1 'Completed initialization' \
 && printf "\n\nDownloading jenkins-cli\n" \
 && curl -s http://localhost:8080/jnlpJars/jenkins-cli.jar -O \
 && printf "\n\nUpdating jenkins plugins\n" \
 && jenkins-cli list-plugins | awk '/)$/ {print $1}' \
  | xargs -n 1 jenkins-cli install-plugin \
 && printf "\n\nInstalling extra plugins\n" \
 && jenkins-cli install-plugin workflow-aggregator \
 && jenkins-cli install-plugin workflow-multibranch \
 && jenkins-cli install-plugin docker-workflow \
 && jenkins-cli install-plugin git \
 && jenkins-cli install-plugin docker-plugin \
 && jenkins-cli install-plugin mock-slave \
 && printf "\n\nRestarting Jenkins\n" \
 && jenkins-cli safe-restart \
 && printf "\n\nWaiting for jenkins to initialize\n" \
 && sleep 1; tail -f /tmp/jenkins.log | grep -qm 1 'Completed initialization' \
 && jenkins-cli list-plugins | sort \
 && jenkins-cli safe-shutdown \
 && sleep 5
#  ; rm /tmp/jenkins.log

COPY config.xml /var/jenkins_home/config.xml
