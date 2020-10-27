# Android development environment for ubuntu.
# version 0.0.5

FROM ubuntu

MAINTAINER behring <behring.zhao@gmail.com>

ARG emulator_version=24
ARG emulator_arch=armeabi-v7a
ARG emulator_api=default

# Specially for SSH access and port redirection
ENV ROOTPASSWORD android

# Expose ADB, ADB control and VNC ports
EXPOSE 22
EXPOSE 5037
EXPOSE 5554
EXPOSE 5555
EXPOSE 5900
EXPOSE 80
EXPOSE 443

ENV DEBIAN_FRONTEND noninteractive
RUN echo "debconf shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections && \
    echo "debconf shared/accepted-oracle-license-v1-1 seen true" | debconf-set-selections

# Update packages
RUN apt-get -y update && \
    apt-get -y install unzip ssh net-tools openssh-server socat curl openjdk-8-jdk vim && \
    rm -rf /var/lib/apt/lists/*

# Install android sdk
RUN wget -P /usr/local/ https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip && \
    unzip /usr/local/sdk-tools-linux-4333796.zip -d /usr/local/android-sdk && \
    chown -R root:root /usr/local/android-sdk/

# Add android tools and platform tools to PATH
ENV ANDROID_HOME /usr/local/android-sdk
ENV PATH $ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH

# Export JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# Install latest android tools and system images（docker unsupport x86 emulator, android-19 to android-24's armeabi-v7a）
RUN yes | $ANDROID_HOME/tools/bin/sdkmanager --list && \
    yes | $ANDROID_HOME/tools/bin/sdkmanager 'emulator' \ 
    'platform-tools' \ 
    "platforms;android-${emulator_version}" \
    "build-tools;${emulator_version}.0.3" \
    "system-images;android-${emulator_version};${emulator_api};${emulator_arch}"

# Create fake keymap file
RUN mkdir /usr/local/android-sdk/tools/keymaps && \
    touch /usr/local/android-sdk/tools/keymaps/en-us

# Run sshd
RUN mkdir /var/run/sshd && \
    echo "root:$ROOTPASSWORD" | chpasswd && \
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    echo "export VISIBLE=now" >> /etc/profile

ENV NOTVISIBLE "in users profile"

# Add entrypoint
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV VERSION $emulator_version
ENV ARCH $emulator_arch
ENV API $emulator_api
ENTRYPOINT /entrypoint.sh $VERSION $API $ARCH
