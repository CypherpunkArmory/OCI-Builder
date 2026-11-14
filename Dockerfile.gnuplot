# The gnuplot app's image: userland-debian plus gnuplot. Built on the base rather than from
# debian:latest so it carries the base's /support files and fixes; build-gnuplot.yml rebuilds
# it whenever the base is rebuilt.
FROM ghcr.io/cypherpunkarmory/userland-debian:next

COPY apps/gnuplot.sh /tmp/app.sh
RUN sh /tmp/app.sh && rm /tmp/app.sh
