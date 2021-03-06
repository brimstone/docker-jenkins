FROM docker:dind

EXPOSE 8080

ENTRYPOINT ["/sbin/runsvdir", "/service"]

# tini
RUN apk add --update \
    --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
    --repository http://dl-3.alpinelinux.org/alpine/edge/community/ \
    runit openjdk8-jre ttf-dejavu git bash \
 && rm -rf /var/cache/apk/*

# docker

ENV DOCKER_OPTS "--host=unix:///var/run/docker.sock --storage-driver=overlay"

# jenkins
ENV JENKINS_UC=https://updates.jenkins-ci.org
ENV JENKINS_HOME /var/jenkins_home

RUN addgroup docker \
 && adduser -h "$JENKINS_HOME" -u 1000 -s /bin/sh -D -G docker jenkins jenkins

RUN mkdir -p /usr/share/jenkins/ref \
 && curl -fL \
    http://mirrors.jenkins-ci.org/war-stable/latest/jenkins.war \
    -o /usr/share/jenkins/jenkins.war \
 && chown -R jenkins: /usr/share/jenkins

COPY jenkins /bin/

COPY jenkins-cli /bin/

#VOLUME /var/jenkins_home

COPY plugins.txt /plugins.txt

RUN cd "$JENKINS_HOME" \
 && /bin/jenkins 2>&1 | tee /tmp/jenkins.log \
  & printf "\n\nWaiting for jenkins to initialize\n" \
 && sleep 1; tail -f /tmp/jenkins.log | grep -qm 1 'Completed initialization' \
 && printf "\n\nDownloading jenkins-cli\n" \
 && curl -s http://localhost:8080/jnlpJars/jenkins-cli.jar > /bin/jenkins-cli.jar \
 && printf "\n\nUpdating jenkins plugins\n" \
 && jenkins-cli list-plugins | awk '/)$/ {print $1}' \
  | xargs -n 1 jenkins-cli install-plugin \
 && printf "\n\nInstalling extra plugins\n" \
 && while read -r aplugin; \
 do jenkins-cli install-plugin "$aplugin" \
 ; done < /plugins.txt \
 && printf "\n\nAdding SSH Creds\n" \
 && curl -XPOST 'localhost:8080/credential-store/domain/_/createCredentials' \
  --data-urlencode 'json={ \
      "": "0", \
      "credentials": { \
          "scope": "GLOBAL", \
          "id": "slave-dind", \
          "username": "jenkins", \
          "password": "jenkins", \
          "description": "slave-dind", \
          "$class": "com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl" \
      } \
  }' \
 && printf "\n\nRestarting Jenkins\n" \
 && jenkins-cli safe-restart \
 && sleep 15 \
 && printf "\n\nWaiting for jenkins to initialize\n" \
 && until jenkins-cli list-plugins 2>/dev/null; do sleep 1; done | sort \
 && jenkins-cli safe-shutdown \
 && printf "\n\nWaiting for jenkins to shutdown\n" \
 && while pgrep java; do sleep 1; done \
 && chown -R jenkins: "$JENKINS_HOME" \
 && printf "\n\nBacking up jenkins home directory\n" \
 && tar -zcf /usr/share/jenkins/home.orig.tar.gz -C "$JENKINS_HOME" . \
 && rm -rf "$JENKINS_HOME"/*

COPY config.xml /usr/share/jenkins/config.orig.xml

COPY service /service

ONBUILD RUN while read -r aplugin; \
 do jenkins-cli install-plugin "$aplugin" \
 ; done < /plugins.txt \
