#!/bin/bash
set -e

BUILD_TYPE=Release
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#BASE_OSGEARTH_BRANCH="osgearth-3.1"
#BASE_OSGEARTH_BRANCH="osgearth-3.2"
BASE_OSGEARTH_BRANCH="master"

# Version 3.7 dated 2021/07/25
#OSG_COMMIT="76a58ebaf495cc6656db2094ed39f09704e3c81e"

# Version 3.2 dated 2021/7/29
#OSGEARTH_COMMIT="3c3660ffbf94bfb0f262f1a523102a5fa1b0c412"

export MACOSX_DEPLOYMENT_TARGET=10.9
export OSG_NOTIFY_LEVEL=Warn
export OSGEARTH_NOTIFY_LEVEL=Warn
export GDAL_DATA=$SCRIPT_DIR/homebrew/share/gdal
export OSGEARTH_REX_NO_POOL=1

function build_osg() {
  mkdir -p ./src/

  if [ ! -d ./src/osg ]; then
    git clone https://github.com/openscenegraph/OpenSceneGraph.git src/osg -b OpenSceneGraph-3.6.5
    
    pushd src/osg

    # If requested, check out a specific commit
    if [ "$OSG_COMMIT" != "" ]; then
      git checkout $OSG_COMMIT
    fi

    # Apply any local patches
    if [ -d $SCRIPT_DIR/patches/osg ]; then
      for patch in $SCRIPT_DIR/patches/osg/*.patch
      do
        patch -p1 < $patch
      done
    fi
    popd
  fi

  mkdir -p ./_build_$BUILD_TYPE/osg
  pushd ./_build_$BUILD_TYPE/osg
  cmake \
    -GXcode \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
    -DCMAKE_PREFIX_PATH=$SCRIPT_DIR/homebrew \
    -DCMAKE_INSTALL_PREFIX=$SCRIPT_DIR/install_$BUILD_TYPE \
    -DOSG_BUILD_APPLICATION_BUNDLES=OFF \
    -DOSG_WINDOWING_SYSTEM=Cocoa \
    -DOPENGL_PROFILE=GLCORE \
    -DCMAKE_CXX_STANDARD:STRING=11 \
    -DCMAKE_CXX_STANDARD_REQUIRED:BOOL=ON \
    -DCMAKE_CXX_EXTENSIONS:BOOL=OFF \
    -DCMAKE_VISIBILITY_INLINES_HIDDEN:BOOL=TRUE \
    -DCMAKE_MACOSX_RPATH:BOOL=TRUE \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9 \
    -DCMAKE_RELWITHDEBINFO_POSTFIX="" \
    -DCMAKE_MINSIZEREL_POSTFIX="s" \
    ../../src/osg
  cmake --build . --config $BUILD_TYPE --target install
  popd
}

function build_osgearth() {
  mkdir -p ./src/

  if [ ! -d ./src/osgEarth ]; then
    git clone https://github.com/gwaldron/osgearth.git src/osgEarth -b $BASE_OSGEARTH_BRANCH
    pushd src/osgEarth

    # If requested, check out a specific commit
    if [ "$OSGEARTH_COMMIT" != "" ]; then
      git checkout $OSGEARTH_COMMIT
    fi

    # Apply any local patches
    if [ -d $SCRIPT_DIR/patches/osgearth ]; then
      for patch in $SCRIPT_DIR/patches/osgearth/*.patch
      do
        patch -p1 < $patch
      done
    fi
    popd
  fi

  mkdir -p ./_build_$BUILD_TYPE/osgearth
  pushd ./_build_$BUILD_TYPE/osgearth
  # Need to explicitly include GLEW headers and libraries below (using -DGLEW_*).  Unsure why.
  
  cmake \
    -GXcode \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
    -DOSG_DIR=$SCRIPT_DIR/_build_$BUILD_TYPE/osg \
    -DCMAKE_PREFIX_PATH="$SCRIPT_DIR/homebrew;$SCRIPT_DIR/install_$BUILD_TYPE" \
    -DGLEW_INCLUDE_DIR="$SCRIPT_DIR/homebrew/include" \
    -DGLEW_LIBRARIES="$SCRIPT_DIR/homebrew/lib/libGLEW.a" \
    -DCMAKE_INSTALL_PREFIX=$SCRIPT_DIR/install_$BUILD_TYPE \
    -DCMAKE_POLICY_DEFAULT_CMP0063=NEW \
    -DCMAKE_VISIBILITY_INLINES_HIDDEN:BOOL=TRUE \
    -DCMAKE_MACOSX_RPATH:BOOL=TRUE \
    -DCURL_NO_CURL_CMAKE:BOOL=YES \
    -DOSGEARTH_BUILD_ROCKSDB_CACHE:BOOL=YES \
    -DOSGEARTH_BUILD_TESTS:BOOL=NO \
    -DCMAKE_CXX_STANDARD:STRING=11 \
    -DCMAKE_CXX_STANDARD_REQUIRED:BOOL=ON \
    -DCMAKE_CXX_EXTENSIONS:BOOL=OFF \
    -DCMAKE_VISIBILITY_INLINES_HIDDEN:BOOL=TRUE \
    -DCMAKE_MACOSX_RPATH:BOOL=TRUE \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9 \
    ../../src/osgEarth
  cmake --build . --config $BUILD_TYPE --target install
  popd
}

# If necessary, install a local copy of homebrew that will be used to install
# dependencies
if [ ! -d ./homebrew ]; then
  mkdir -p homebrew 
  curl -L https://github.com/Homebrew/brew/archive/refs/tags/3.2.5.tar.gz | tar xz --strip 1 -C homebrew
fi

./homebrew/bin/brew install libzip 
./homebrew/bin/brew install tcl-tk
./homebrew/bin/brew install ffmpeg 
./homebrew/bin/brew install gdal 
./homebrew/bin/brew install glew
./homebrew/bin/brew install protobuf

# Parse script options
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    relwithdebinfo)
      BUILD_TYPE=RelWithDebInfo
      shift
      ;;
    debug)
      BUILD_TYPE=Debug
      shift
      ;;
    osg)
      OSG="true"
      shift # past argument
      ;;
    osgearth)
      OSGEARTH="true"
      shift # past argument
      ;;
    all)
      OSG="true"
      OSGEARTH="true"
      shift
      ;;
    clean)
      CLEAN="true"
      shift
      ;;
    osgversion)
      OSGVERSION="true"
      shift
      ;;
    osgviewer)
      OSGVIEWER="true"
      shift
      ;;
    osgearthviewer)
      OSGEARTHVIEWER="true"
      shift
      ;;
    showcaps)
      SHOW_CAPS="true"
      shift
      ;;
    *)    # unknown option
      echo "Unknown command $1"
      shift
      exit 1
      ;;
  esac
done

# Clean any existing artifacts if requested
if [ "$CLEAN" == "true" ]; then
  rm -rf $SCRIPT_DIR/src
  rm -rf $SCRIPT_DIR/install_$BUILD_TYPE
  rm -rf $SCRIPT_DIR/_build_$BUILD_TYPE
fi

# Build OSG is requested
if [ "$OSG" == "true" ]; then
  build_osg
fi

# Build osgEarth if requested
if [ "$OSGEARTH" == "true" ]; then
  build_osgearth
fi

# Run any test applications (osgviewer, osgearth_viewer, etc) if requested.
if [ "$BUILD_TYPE" == "Debug" ]; then
  EXE_SUFFIX="d"
fi

export DYLD_LIBRARY_PATH=$SCRIPT_DIR/install_$BUILD_TYPE/lib 
export PATH=$PATH:$SCRIPT_DIR/install_$BUILD_TYPE/bin 

if [ "$OSGVIEWER" == "true" ]; then
  if [ ! -d $SCRIPT_DIR/data ]; then
    git clone https://github.com/openscenegraph/OpenSceneGraph-Data.git data
  fi
  osgviewer$EXE_SUFFIX $SCRIPT_DIR/data/cessna.osg --window 100 100 800 600 --gl-version 4.9
fi

if [ "$OSGVERSION" == "true" ]; then
  osgversion$EXE_SUFFIX
fi

if [ "$OSGEARTHVIEWER" == "true" ]; then
  osgearth_viewer$EXE_SUFFIX $SCRIPT_DIR/src/osgEarth/tests/readymap.earth --window 100 100 800 600
fi

if [ "$SHOW_CAPS" == "true" ]; then
  osgearth_version$EXE_SUFFIX --caps
fi
