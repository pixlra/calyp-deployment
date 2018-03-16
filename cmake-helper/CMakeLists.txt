###
### CMakeLists for playuver
###

cmake_minimum_required( VERSION 2.8.9 )

######################################################################################
# Project Definition
######################################################################################

SET( PROJECT_NAME "calyp" )

PROJECT( ${PROJECT_NAME} )

SET(PACKAGE_NAME "" CACHE STRING "Tag instead of version" )

ADD_SUBDIRECTORY( calyp)
INCLUDE( BuildPkg.cmake )

