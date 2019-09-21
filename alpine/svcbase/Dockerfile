FROM alpine:latest

ENV LANG C.UTF-8
ENV EDITOR vi
ENV SVC svc

RUN apk add --no-cache sudo bash openssh \
    && adduser -h /usr/local/$SVC -s /bin/bash -S $SVC wheel \
        && sudoer=$SVC && sudo sh -c "echo \"$sudoer ALL=(ALL:ALL) NOPASSWD:ALL\" > /etc/sudoers.d/$sudoer" \
        && echo "export PS1=\"...\W# \"" > /usr/local/$SVC/.bash_profile \
        && chown $SVC:$SVC /usr/local/$SVC \
    && rm -rf /root/.cache
