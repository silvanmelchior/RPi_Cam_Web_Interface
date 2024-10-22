#!/bin/bash
set -e

LIBCAMERA_REMOTE=https://github.com/raspberrypi/libcamera.git
RPICAM_APPS_REMOTE=git@github.com:consiliumsolutions/p05a-rpicam-apps.git

# Compile and install libcamera from source
install_libcamera() {
    set -e
    git clone "$LIBCAMERA_REMOTE" libcamera
    cd libcamera

    sudo apt install -y python3-pip git python3-jinja2 \
        libboost-dev \
        libgnutls28-dev openssl libtiff-dev pybind11-dev \
        qtbase5-dev libqt5core5a libqt5widgets5 \
        meson cmake \
        python3-yaml python3-ply \
        libglib2.0-dev libgstreamer-plugins-base1.0-dev

    meson setup build --buildtype=release -Dpipelines=rpi/vc4,rpi/pisp -Dipas=rpi/vc4,rpi/pisp -Dv4l2=true -Dgstreamer=enabled -Dtest=false -Dlc-compliance=disabled -Dcam=disabled -Dqcam=disabled -Ddocumentation=disabled -Dpycamera=enabled
    sudo ninja -C build install

    cd ..
}

# Compile and install rpicam-mjpeg from source

install_rpicam_mjpeg() {
    set -e
    git clone "$RPICAM_APPS_REMOTE" rpicam-apps
    cd rpicam-apps

    sudo apt install -y cmake libboost-program-options-dev libdrm-dev libexif-dev libavdevice-dev libpng-dev libepoxy-dev\
        meson ninja-build

    meson setup build -Denable_libav=enabled -Denable_drm=enabled -Denable_egl=enabled -Denable_qt=enabled -Denable_opencv=disabled -Denable_tflite=disabled
    meson compile -C build
    sudo meson install -C build

    cd ..
}

if [ -d ./work ]; then
    rm -rf work
fi

mkdir ./work
pushd ./work

install_libcamera
install_rpicam_mjpeg

popd

# Create a symlink for install.sh to install
if [ -e ./raspimjpeg ]; then
    mv ./raspimjpeg ./raspimjpeg.bak
fi

ln -s `which rpicam-mjpeg` ./raspimjpeg
