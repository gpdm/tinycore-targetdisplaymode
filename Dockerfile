FROM tatsushid/tinycore

ENV TC_ISO_URL="${TC_ISO_URL:-http://www.tinycorelinux.net/13.x/x86/release/TinyCore-current.iso}"

# in relation to issue #3,
# try to capture error state while running tce-load command
RUN set -o pipefail && \
    tce-load -wic bash.tcz libisoburn.tcz git.tcz gcc.tcz compiletc.tcz ; echo $?

# get rid of pre-registered packages
RUN rm -rf /tmp/tce/optional/*

# also in relation to #3,
# double-check via tce-status if given packages are actually installed
RUN tce-status -i | grep -Ee '^(bash|libisoburn|git|gcc|compiletc)$'

ADD files /tmp/build 

USER root:root
ENTRYPOINT /tmp/build/build.sh
