FROM tatsushid/tinycore

RUN tce-load -wic bash.tcz libisoburn.tcz git.tcz gcc.tcz compiletc.tcz ; \
    rm -rf /tmp/tce/optional/*

ADD files /tmp/build 

USER root:root
ENTRYPOINT /tmp/build/build.sh
