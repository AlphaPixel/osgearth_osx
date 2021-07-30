# osgearth_osx

This repository is used for building OSG and osgEarth on Macos/OSX.   It installs a private (versioned) copy of homebrew for all dependencies (to keep from using a system's brew installation)

Prerequisites:
  CMake 3.21 (this version is important for properly building the below)

## Building OSG/OSGEarth and dependencies 
```shell
$ bash build.sh relwithdebinfo osg osgearth
```

The above perform the following:
1) Install a local versioned copy of homebrew (into the directory containing this script).
2) Install OSG and OSGEarth dependencies using local homebrew (installed to $SCRIPT_DIR/homebrew)
3) Builds OSG using CMake's "RelWithDebInfo" build type (installed to $SCRIPT_DIR/install_$BUILD_TYPE)
4) Builds osgEarth using CMake's "RelWithDebInfo" build type (installed to $SCRIPT_DIR/install_$BUILD_TYPE)

## Running osgviewer and osgearth_viewer
```shell
$ bash build.sh relwithdebinfo osgviewer
```

``` shell
$ bash build.sh relwithdebinfo osgearthviewer
```
