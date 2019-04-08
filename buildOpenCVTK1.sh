#!/bin/bash

OPENCV_VERSION=3.4.2
OPENCV_SOURCE_DIR=$HOME

echo "This script will build and install OpenCV 3.4.2 with CUDA support on the TK1"

echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y \
    cmake \
    libglew-dev \
    libtiff5-dev \
    zlib1g-dev \
    libjpeg-dev \
    libpng12-dev \
    libjasper-dev \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libpostproc-dev \
    libswscale-dev \
    libv4l-dev \
    libeigen3-dev \
    libtbb-dev \
    libgtk2.0-dev \
    pkg-config

cd $OPENCV_SOURCE_DIR
echo "Cloning OpenCV repo..."
git clone https://github.com/opencv/opencv.git
cd opencv
echo "Checking out branch..."
git checkout -b v${OPENCV_VERSION} ${OPENCV_VERSION}

cd $OPENCV_SOURCE_DIR
echo "Cloning OpenCV Contrib repo..."
git clone https://github.com/opencv/opencv_contrib.git
cd opencv_contrib
echo "Checking out branch..."
git checkout -b v${OPENCV_VERSION} ${OPENCV_VERSION}

echo "Installing Python 2..."
sudo apt-get install -y python-dev python-numpy python-py python-pytest

echo "Installing Python 3..."
sudo apt-get install -y python3-dev python3-numpy python3-py python3-pytest

echo "Preparing build..."
cd $OPENCV_SOURCE_DIR/opencv
mkdir build
cd build

echo "Configuring CMake..."
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_CXX_FLAGS=-Wa,-mimplicit-it=thumb \
    -DBUILD_PNG=OFF \
    -DBUILD_TIFF=OFF \
    -DBUILD_TBB=OFF \
    -DBUILD_JPEG=OFF \
    -DBUILD_JASPER=OFF \
    -DBUILD_ZLIB=OFF \
    -DBUILD_EXAMPLES=ON \
    -DBUILD_opencv_java=OFF \
    -DBUILD_opencv_python2=ON \
    -DBUILD_opencv_python3=ON \
    -DENABLE_NEON=ON \
    -DWITH_OPENCL=OFF \
    -DWITH_OPENMP=OFF \
    -DWITH_FFMPEG=ON \
    -DWITH_GSTREAMER=OFF \
    -DWITH_GSTREAMER_0_10=OFF \
    -DWITH_CUDA=ON \
    -DWITH_GTK=ON \
    -DWITH_VTK=OFF \
    -DWITH_TBB=ON \
    -DWITH_1394=OFF \
    -DWITH_OPENEXR=OFF \
    -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda-6.5 \
    -DCUDA_ARCH_BIN=3.2 \
    -DCUDA_ARCH_PTX="" \
    -DINSTALL_C_EXAMPLES=ON \
    -DINSTALL_TESTS=OFF \
    -DOPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
    ../

if [ $? -eq 0 ] ; then
  echo "CMake configuration make successful"
else
  # Try to make again
  echo "CMake issues " >&2
  echo "Please check the configuration being used"
  exit 1
fi

time make -j3
if [ $? -eq 0 ] ; then
  echo "OpenCV make successful"
else
  # Try to make again; Sometimes there are issues with the build
  # because of lack of resources or concurrency issues
  echo "Make did not build " >&2
  echo "Retrying ... "
  # Single thread this time
  make
  if [ $? -eq 0 ] ; then
    echo "OpenCV make successful"
  else
    # Try to make again
    echo "Make did not successfully build" >&2
    echo "Please fix issues and retry build"
    exit 1
  fi
fi

echo "Installing ... "
sudo make install
if [ $? -eq 0 ] ; then
   echo "OpenCV installed"
else
   echo "There was an issue with the final installation"
   exit 1
fi
