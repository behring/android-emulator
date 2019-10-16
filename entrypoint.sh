#!/bin/bash

if [[ $EMULATOR == "" ]]; then
    EMULATOR="android-24"
    echo "Using default emulator $EMULATOR"
fi

echo EMULATOR  = "Requested API: ${EMULATOR} (${ARCH}) emulator."
if [[ -n $1 ]]; then
    echo "Last line of file specified as non-opt/last argument:"
    tail -1 $1
fi

# Run sshd
/usr/sbin/sshd

# Detect ip and forward ADB ports outside to outside interface
ip=$(ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}')
socat tcp-listen:5037,bind=$ip,fork tcp:127.0.0.1:5037 &
socat tcp-listen:5554,bind=$ip,fork tcp:127.0.0.1:5554 &
socat tcp-listen:5555,bind=$ip,fork tcp:127.0.0.1:5555 &
socat tcp-listen:80,bind=$ip,fork tcp:127.0.0.1:80 &
socat tcp-listen:443,bind=$ip,fork tcp:127.0.0.1:443 &

echo no | /usr/local/android-sdk/tools/bin/avdmanager create avd -n test -k "system-images;${EMULATOR};default;armeabi-v7a"
/usr/local/android-sdk/tools/emulator -avd test -noaudio -no-window -gpu off

