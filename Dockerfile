FROM ubuntu:24.04

RUN apt update && apt install -y \
    make \
    gcc \
    git

COPY build-i2c.sh /opt/build-i2c.sh

CMD ["/opt/build-i2c.sh"]
