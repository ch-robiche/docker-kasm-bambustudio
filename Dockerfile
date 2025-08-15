# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-kasmvnc:debianbookworm

# set version label
ARG BUILD_DATE=""
ARG VERSION=""
ARG BAMBUSTUDIO_VERSION=""
LABEL build_version="Linuxserver.io version=${VERSION} build-date=${BUILD_DATE}"
LABEL maintainer="thelamer"

# title
ENV TITLE=BambuStudio
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

RUN \
  echo "**** add icon ****" && \
  curl -fsSL -o /kclient/public/icon.png \
    https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/bambustudio-logo.png && \
  echo "**** install packages ****" && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    firefox-esr \
    fonts-dejavu \
    fonts-dejavu-extra \
    gstreamer1.0-alsa \
    gstreamer1.0-gl \
    gstreamer1.0-gtk3 \
    gstreamer1.0-libav \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-pulseaudio \
    gstreamer1.0-qt5 \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    libgstreamer1.0-0 \
    libgstreamer-plugins-bad1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    libosmesa6 \
    libwebkit2gtk-4.0-37 \
    libwx-perl \
    locales && \
  echo "**** install bambu studio from appimage ****" && \
  if [ -z "${BAMBUSTUDIO_VERSION+x}" ] || [ -z "${BAMBUSTUDIO_VERSION}" ]; then \
    BAMBUSTUDIO_VERSION=$(curl -fsSL "https://api.github.com/repos/bambulab/BambuStudio/releases/latest" \
      | awk -F'"' '/tag_name/{print $4;exit}'); \
  fi && \
  RELEASE_URL=$(curl -fsSL "https://api.github.com/repos/bambulab/BambuStudio/releases/tags/${BAMBUSTUDIO_VERSION}" \
      | awk -F'"' '/url/{print $4;exit}') && \
  DOWNLOAD_URL=$(curl -fsSL "${RELEASE_URL}" \
      | awk -F'"' '/browser_download_url/ && /AppImage/{print $4;exit}') && \
  cd /tmp && \
  curl -fsSL -o /tmp/bambu.app "${DOWNLOAD_URL}" && \
  chmod +x /tmp/bambu.app && \
  /tmp/bambu.app --appimage-extract && \
  mv squashfs-root /opt/bambustudio && \
  # locale setup (needed by some UIs)
  sed -i 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen && \
  locale-gen && \
  localedef -i en_GB -f UTF-8 en_GB.UTF-8 || true && \
  printf "Linuxserver.io version: %s\nBuild-date: %s" "${VERSION}" "${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  apt-get autoclean && \
  rm -rf /config/.cache /config/.launchpadlib /var/lib/apt/lists/* /var/tmp/* /tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 3000
VOLUME ["/config"]
