FROM ubuntu:18.04
LABEL maintainer="slu125"

ARG DEBIAN_FRONTEND="noninteractive"
ARG APT_MIRROR="archive.ubuntu.com"

ARG PLEXDRIVE_VERSION="5.1.0"
ARG PLATFORM_ARCH="amd64"

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV S6_KEEP_ENV=1

ENV LANG=C.UTF-8
ENV PS1="\u@\h:\w\\$ "

RUN \
 echo "**** apt source change for local build ****" && \
 sed -i "s/archive.ubuntu.com/\"$APT_MIRROR\"/g" /etc/apt/sources.list && \
 echo "**** install runtime packages ****" && \
 apt-get update && \
 apt-get install -y \
	ca-certificates \
	fuse \
	tzdata \
	unionfs-fuse \
	encfs && \
 update-ca-certificates && \
 apt-get install -y openssl && \
 sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf && \
 echo "**** install build packages ****" && \
 apt-get install -y \
	curl \
	unzip \
	wget && \
 echo "**** add s6 overlay ****" && \
 OVERLAY_VERSION=$(curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]') && \
 curl -o /tmp/s6-overlay.tar.gz -L "https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-amd64.tar.gz" && \
 tar xfz  /tmp/s6-overlay.tar.gz -C / && \
 echo "**** add plexdrive ****" && \
 cd $(mktemp -d) && \
 wget https://github.com/plexdrive/plexdrive/releases/download/${PLEXDRIVE_VERSION}/plexdrive-linux-${PLATFORM_ARCH} && \
 mv plexdrive-linux-${PLATFORM_ARCH} /usr/bin/plexdrive && \
 chmod 777 /usr/bin/plexdrive && \
 echo "**** create abc user ****" && \
 groupmod -g 1000 users && \
 useradd -u 911 -U -d /config -s /bin/false abc && \
 usermod -G users abc && \
 echo "**** cleanup ****" && \
 apt-get purge -y \
	curl \
	unzip \
	wget && \
 apt-get clean autoclean && \
 apt-get autoremove -y && \
 rm -rf /tmp/* /var/lib/{apt,dpkg,cache,log}/

COPY root/ /

ENV UFS_USER_OPTS "cow,direct_io,nonempty,auto_cache,sync_read"

ENTRYPOINT ["/init"]
