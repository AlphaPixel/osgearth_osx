project(osgearth_builder)

cmake_minimum_required(VERSION 3.21)

# Policies
cmake_policy(SET CMP0063 NEW)


set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_SOURCE_DIR}/install")
list(APPEND CMAKE_PREFIX_PATH "${CMAKE_CURRENT_SOURCE_DIR}/homebrew")
list(APPEND CMAKE_PREFIX_PATH "${CMAKE_CURRENT_SOURCE_DIR}/install")

set(CMAKE_MACOSX_RPATH ON)
set(CURL_NO_CURL_CMAKE ON)

include(FetchContent)

#
# OpenSceneGraph
#
FetchContent_Declare(
    osg
    GIT_REPOSITORY https://github.com/openscenegraph/OpenSceneGraph.git
    GIT_TAG        OpenSceneGraph-3.6.5
)
FetchContent_MakeAvailable(osg)

#set_property(TARGET osg PROPERTY CXX_STANDARD 11)
#set_property(TARGET osg PROPERTY CXX_STANDARD_REQUIRED ON)
#set_property(TARGET osg PROPERTY CXX_EXTENSIONS OFF)
#set_property(TARGET osg PROPERTY CMAKE_VISIBILITY_INLINES_HIDDEN ON)

set(OSG_BUILD_APPLICATION_BUNDLES OFF)
set(OSG_WINDOWING_SYSTEM Cocoa)
set(OPENGL_PROFILE GLCORE)
set(APPEND_OPENSCENEGRAPH_VERSION NO)

#
# osgEarth
#
FetchContent_Declare(
    osge
    GIT_REPOSITORY https://github.com/gwaldron/osgearth.git
    GIT_TAG        6b6ef7500dad4adeadc450cbc86cfd22c5b29b39
    PATCH_COMMAND  bash ${CMAKE_CURRENT_SOURCE_DIR}/patch.sh "${CMAKE_CURRENT_SOURCE_DIR}/patches/osgearth"
)
FetchContent_MakeAvailable(osge)

#set_property(TARGET osgearth PROPERTY CXX_STANDARD 11)
#set_property(TARGET osgearth PROPERTY CXX_STANDARD_REQUIRED YES)
#set_property(TARGET osgearth PROPERTY CXX_EXTENSIONS OFF)
#set_property(TARGET osgearth PROPERTY CMAKE_VISIBILITY_INLINES_HIDDEN ON)

add_dependencies(osgEarth osg)

set(OSGEARTH_BUILD_ROCKSDB_CACHE YES)
set(OSGEARTH_BUILD_TESTS NO)

add_executable(test main.cpp)

target_link_libraries(test osg osgearth)
