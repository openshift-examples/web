FROM alpine:latest

RUN apk --update add socat curl busybox-extras
RUN mkdir /www/ && chmod 770 /www/
ADD srv.sh /www/srv.sh
EXPOSE 8080

USER 1984

CMD socat TCP4-LISTEN:8080,fork EXEC:/www/srv.sh
