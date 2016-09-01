FROM alpine:latest

RUN apk update && \
  apk add openssh && \
  rm -rf /var/cache/apk/* && \
  mkdir -p /root/.ssh && \
  chmod 700 /root/.ssh/

ADD sshd_config /etc/ssh/sshd_config
ADD banner /
ADD init.sh /
EXPOSE 22
CMD /init.sh
