FROM buildpack-deps:jessie

ENV VARNISH_VERSION 4.0.3-2~jessie

RUN apt-get update \
        && apt-get install apt-transport-https \
        && curl https://repo.varnish-cache.org/GPG-key.txt | apt-key add - \
        && echo "deb https://repo.varnish-cache.org/debian/ jessie varnish-4.0" >> /etc/apt/sources.list.d/varnish-cache.list \
        && apt-get update \
        && apt-get install -y varnish=$VARNISH_VERSION

COPY varnish.vcl /etc/varnish.vcl

CMD ["varnishd", "-F", "-f", "/etc/varnish.vcl"]
