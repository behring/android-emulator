#!/bin/bash
VERSION=$1
API=$2
ARCH=$3
NAME="docker-emulator"
if [[ $VERSION == "" ]]; then
    VERSION="24"
    echo "Using default emulator android-$VERSION"
fi

if [[ $ARCH == "" ]]; then
    ARCH="armeabi-v7a"
    echo "Using default arch $ARCH"
fi

if [[ $API == "" ]]; then
    API="default"
    echo "Using $API api"
fi

echo EMULATOR  = "Requested API: android-$VERSION ($API,$ARCH) emulator."

# Run sshd
/usr/sbin/sshd

# Detect ip and forward ADB ports outside to outside interface
ip=$(ifconfig|grep inet|grep -v 127.0.0.1|awk "{print \$2}")
socat tcp-listen:5037,bind=$ip,fork tcp:127.0.0.1:5037 &
socat tcp-listen:5554,bind=$ip,fork tcp:127.0.0.1:5554 &
socat tcp-listen:5555,bind=$ip,fork tcp:127.0.0.1:5555 &
socat tcp-listen:80,bind=$ip,fork tcp:127.0.0.1:80 &
socat tcp-listen:443,bind=$ip,fork tcp:127.0.0.1:443 &

echo no | /usr/local/android-sdk/tools/bin/avdmanager create avd -n $NAME -k "system-images;android-$VERSION;$API;$ARCH"
/usr/local/android-sdk/tools/emulator -avd $NAME -noaudio -no-window -gpu off

