FROM tatsushid/tinycore

ENV TC_ISO_URL="${TC_ISO_URL:-http://www.tinycorelinux.net/13.x/x86/release/TinyCore-current.iso}"

RUN tce-load -wic bash.tcz libisoburn.tcz git.tcz gcc.tcz compiletc.tcz && \
    rm -rf /tmp/tce/optional/*

ADD files /tmp/build 

USER root:root
ENTRYPOINT /tmp/build/build.sh
