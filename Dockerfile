FROM docker:dind
MAINTAINER Joern Domnik <j.domnik+docker@gmail.com>

RUN apk --update add openjdk8

ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
RUN export JAVA_HOME