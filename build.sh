set -e

BUILD_TYPE=Release
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

function build_osg() {
    mkdir -p ./src/

    if [ ! -d ./src/osg ]; then
        git clone https://github.com/openscenegraph/OpenSceneGraph.git src/osg -b OpenSceneGraph-3.6.5
        if [ -d $SCRIPT_DIR/patches/osg ]; then
            pushd src/osg

            for patch in patches/osg/*.patch
            do
                patch -p1 < $patch
            done

            popd
        fi
    fi

    mkdir -p ./_build_$BUILD_TYPE/osg
    pushd ./_build_$BUILD_TYPE/osg
    cmake \
        -DCMAKE_PREFIX_PATH=$SCRIPT_DIR/homebrew \
        -DCMAKE_INSTALL_PREFIX=$SCRIPT_DIR/install_$BUILD_TYPE \
        -DOSG_BUILD_APPLICATION_BUNDLES=OFF \
        -DOSG_WINDOWING_SYSTEM=Cocoa \
        -DOPENGL_PROFILE=GLCORE \
        -DAPPEND_OPENSCENEGRAPH_VERSION:BOOL=FALSE \
        -DCMAKE_CXX_STANDARD:STRING=11 \
        -DCMAKE_CXX_STANDARD_REQUIRED:BOOL=ON \
        -DCMAKE_CXX_EXTENSIONS:BOOL=OFF \
        -DCMAKE_VISIBILITY_INLINES_HIDDEN:BOOL=TRUE \
        -DCMAKE_MACOSX_RPATH:BOOL=TRUE \
        ../../src/osg
    cmake --build . --target install
    popd
}

function build_osgearth() {
    mkdir -p ./src/

    if [ ! -d ./src/osgEarth ]; then
        git clone https://github.com/gwaldron/osgearth.git src/osgEarth -b osgearth-3.1
        pushd src/osgEarth
        git checkout 6b6ef7500dad4adeadc450cbc86cfd22c5b29b39

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
    # Need to explicitly include GLEW headers and libraries.  Unsure why.
    
    cmake \
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
        ../../src/osgEarth
    cmake --build . --target install
    popd
}

if [ ! -d ./homebrew ]; then
  mkdir -p homebrew 
  curl -L https://github.com/Homebrew/brew/archive/refs/tags/3.2.5.tar.gz | tar xz --strip 1 -C homebrew

  ./homebrew/bin/brew install libzip 
  ./homebrew/bin/brew install ffmpeg 
  ./homebrew/bin/brew install gdal 
  ./homebrew/bin/brew install glew
  ./homebrew/bin/brew install protobuf
fi

POSITIONAL=()
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
    test)
      TEST="true"
      shift
      ;;
    *)    # unknown option
      echo "Unknown command $1"
      shift # past argument
      ;;
  esac
done

if [ "$CLEAN" == "true" ]; then
    rm -rf $SCRIPT_DIR/src
    rm -rf $SCRIPT_DIR/install_$BUILD_TYPE
    rm -rf $SCRIPT_DIR/_build_$BUILD_TYPE
fi

if [ "$OSG" == "true" ]; then
    build_osg
fi

if [ "$OSGEARTH" == "true" ]; then
    build_osgearth
fi

if [ "$TEST" == "true" ]; then
  export PATH=$PATH:$SCRIPT_DIR/install_$BUILD_TYPE/bin 
  export OSG_NOTIFY_LEVEL=Debug
  export OSGEARTH_NOTIFY_LEVEL=Debug
  export DYLD_LIBRARY_PATH=$SCRIPT_DIR/install_$BUILD_TYPE/lib 
  osgearth_viewer $SCRIPT_DIR/src/osgEarth/tests/simple.earth
fi
