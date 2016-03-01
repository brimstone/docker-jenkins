jenkins
=======

This is a docker container running jenkins. It's preconfigured with the Pipelines plugin.

Usage
=====

- Start this container with either:
  - `--privileged` and use the internal docker daemon
  - with `-e DOCKER=no` and reconfigure the Docker Cloud to use a valid docker daemon
- The Docker Cloud plugin is configured to run `brimstone/jenkins:slave-dind` which needs `--privileged` to start. Check this if you alter the docker daemon or slave image.
- Add a Multibranch Pipeline project
  - Set a Name
  - Set a Project Repository
    - This repo can be used to test.
  - Set Periodically if not otherwise run to something

Jenkinsfile
===========

Simple example:
```
docker.image("busybox").inside {
	sh "busybox"
}
```

More information in [Cloudbees Documentation](http://documentation.cloudbees.com/docs/cje-user-guide/docker-workflow-sect-inside.html)
