###
### CMakeLists for playuver
###

CMAKE_MINIMUM_REQUIRED(VERSION 3.5.0)

######################################################################################
# Project Definition
######################################################################################

SET( PROJECT_NAME "calyp" )

PROJECT( ${PROJECT_NAME} )

SET(PACKAGE_NAME "" CACHE STRING "Tag instead of version" )

ADD_SUBDIRECTORY( calyp)
INCLUDE( BuildPkg.cmake )

