FROM ghcr.io/home-assistant/base:3.24

COPY run.sh /run.sh
RUN chmod 0755 /run.sh

ARG BUILD_VERSION=1.1.0
ARG BUILD_ARCH=aarch64
LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="app" \
    io.hass.arch="${BUILD_ARCH}" \
    org.opencontainers.image.title="Home Assistant Factory Reset" \
    org.opencontainers.image.description="Manual, confirmed HAOS data-disk wipe via Supervisor API" \
    org.opencontainers.image.source="https://github.com/ge0kan/Home-Assistant-factory-reset"

CMD ["/run.sh"]
