FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive LANG=ru_RU.UTF-8 TZ=Etc/UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
      xvfb x11vnc fluxbox novnc websockify socat \
      ca-certificates wget gnupg locales fonts-liberation fonts-noto-core fonts-noto-color-emoji \
    && sed -i 's/# ru_RU.UTF-8/ru_RU.UTF-8/' /etc/locale.gen \
    && locale-gen \
    && wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get install -y --no-install-recommends /tmp/chrome.deb \
    && rm -f /tmp/chrome.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

EXPOSE 6080 9223
ENTRYPOINT ["/entrypoint.sh"]
