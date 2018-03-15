#!/bin/bash

# Get the directory this script is in
pushd `dirname $0` > /dev/null
SCRIPTPATH=$(pwd -P)
popd > /dev/null

LOG_OUTPUT=/tmp/playuver_build_out
TMPDIR=/tmp/playuver-build

OUTPUT_DIR=/nfs/data/share/PlaYUVerProject

BUILD_NIGHTLY_PKG=0
BUILD_STABLE_PKG=0
VERSION=0.8.0

COUNT=-1; BRANCH_TYPES= ; BRANCH_TYPES_NAMES= ; CMAKE_CFG_BRANCH= ;
let COUNT+=1; BRANCH_TYPES[$COUNT]="stable"; BRANCH_TYPES_NAMES[$COUNT]="stable"; DEB_NAMES[$COUNT]=""; CMAKE_CFG_BRANCH[$COUNT]=""
let COUNT+=1; BRANCH_TYPES[$COUNT]="master"; BRANCH_TYPES_NAMES[$COUNT]="latest"; DEB_NAMES[$COUNT]="-latest"; CMAKE_CFG_BRANCH[$COUNT]="-DRELEASE_BUILD=OFF"
#let COUNT+=1; BRANCH_TYPES[$COUNT]="devel"; BRANCH_TYPES_NAMES[$COUNT]="experimental"; DEB_NAMES[$COUNT]="-experimental"; CMAKE_CFG_BRANCH[$COUNT]=""
BRANCH_COUNT=$COUNT

COUNT=-1; CONDITION_TYPES= ; CONDITION_TYPES_NAMES= ;
let COUNT+=1; CONDITION_TYPES[$COUNT]="-DUSE_FFMPEG=ON -DUSE_OPENCV=ON -DUSE_QT4=OFF"; CONDITION_TYPES_NAMES[$COUNT]="wFFmpeg_wOpenCV_wQT5"
#let COUNT+=1; CONDITION_TYPES[$COUNT]="-DUSE_FFMPEG=ON -DUSE_OPENCV=ON -DUSE_QT4=ON"; CONDITION_TYPES_NAMES[$COUNT]="wFFmpeg_wOpenCV_wQT4"
CONDITION_COUNT=$COUNT


function send_mail()
{
  mail -a ${LOG_OUTPUT} -s "PlaYUVer build  failed" jfmcarreira@gmail.com < /dev/null
  echo/tmp/email.txt

  mail -a ${LOG_OUTPUT} -s "PlaYUVer build  failed" jfmcarreira@gmail.com < /dev/null
}

function RunEchoExit() {
  echo "$@"
  eval $@
  if [ $? -ne 0 ]; then
    echo "Error in last command"
    exit
  fi
}

cd $SCRIPTPATH

git clean -fd

# if [[ ! -d SCRIPTPATH/playuver ]]
# then
#   git submodule update --init --recursive
#   git submodule update --recursive
# fi

for BRANCH_IDX in  $(seq 0 ${BRANCH_COUNT}); do

  cd $SCRIPTPATH

  BRANCH=${BRANCH_TYPES[BRANCH_IDX]}

  RunEchoExit "git -C playuver checkout $BRANCH"
  RunEchoExit "git -C playuver pull"

   for COND_IDX in $(seq 0 ${CONDITION_COUNT}); do

     CMAKE_CFG="-DUPDATE_CHANNEL=${BRANCH_TYPES_NAMES[BRANCH_IDX]} ${CMAKE_CFG_BRANCH[BRANCH_IDX]} ${CONDITION_TYPES[COND_IDX]} "

     [[ -d ${TMPDIR} ]] && rm -R ${TMPDIR}
     mkdir ${TMPDIR}
     cd ${TMPDIR}

     RunEchoExit "cmake -DCMAKE_BUILD_TYPE=Release -DPACKAGE_NAME=${BRANCH_TYPES_NAMES[BRANCH_IDX]} $CMAKE_CFG $SCRIPTPATH"
     RunEchoExit "make -j"
     RunEchoExit "make package"

     DEBFILE=$( find ${TMPDIR} -maxdepth 1 -iname "*.deb" )
     ZIPFILE=$( find ${TMPDIR} -maxdepth 1 -iname "*.zip" )

     mv ${DEBFILE} ${OUTPUT_DIR}/debian/playuver-${BRANCH_TYPES_NAMES[BRANCH_IDX]}-linux-amd64.deb
     mv ${ZIPFILE} ${OUTPUT_DIR}/linux/playuver-${BRANCH_TYPES_NAMES[BRANCH_IDX]}-linux-amd64.zip

     UPDATE_XML=$( find ${TMPDIR} -iname "PlaYUVerUpdate*" )
     mv $UPDATE_XML /nfs/data/share/PlaYUVerProject/

     rm -R ${TMPDIR}

   done

  cd $SCRIPTPATH

  if [[ ! -z ${DEB_NAMES[BRANCH_IDX]} ]]
  then
    if [[ $BUILD_NIGHTLY_PKG == 1 ]]
    then
      cd playuver
      NIGHTLY_VERSION=$( git describe --tags | sed -r 's/-g//g' | sed -r 's/-/./g')
      cd $SCRIPTPATH
      sed "1 s/^.*$/playuver${DEB_NAMES[BRANCH_IDX]} (${NIGHTLY_VERSION}jfmcarreira0) trusty; urgency=low/" debian/changelog | sed -r "$ s/^.*$/ -- Joao Carreira (carreira key) <jfmcarreira@gmail.com>  $(date --rfc-2822)/" > debian/changelog
      tar czf playuver${DEB_NAMES[BRANCH_IDX]}_${NIGHTLY_VERSION}jfmcarreira0.orig.tar.gz playuver/
      cd playuver
      cp ../debian . -R
      sed "s/Source: playuver/Source: playuver${DEB_NAMES[BRANCH_IDX]}/" ../debian/control | sed -r "s/Package: playuver/Package: playuver${DEB_NAMES[BRANCH_IDX]}/" > debian/control
      sed "s/playuver for Debian/playuver${DEB_NAMES[BRANCH_IDX]} for Debian/" ../debian/README.Debian > debian/README.Debian
      debuild -S
      cd $SCRIPTPATH
      dput ppa:jfmcarreira/ppa playuver${DEB_NAMES[BRANCH_IDX]}_${NIGHTLY_VERSION}jfmcarreira0_source.changes
    fi
  else
    if [[ $BUILD_STABLE_PKG == 1 ]]
    then
      cd playuver
      VERSION=$(git describe --tags --abbrev=0)
      cd $SCRIPTPATH
      sed "1 s/^.*$/playuver(${VERSION}jfmcarreira0) trusty; urgency=low/" debian/changelog | sed -r "$ s/^.*$/ -- Joao Carreira (carreira key) <jfmcarreira@gmail.com>  $(date --rfc-2822)/" > debian/changelog
      tar czf playuver_${VERSION}jfmcarreira0.orig.tar.gz playuver/
      cd playuver
      cp ../debian . -R
      debuild -S
      cd $SCRIPTPATH
      dput ppa:jfmcarreira/ppa playuver_${VERSION}jfmcarreira0_source.changes
    fi
  fi

done

DEB_INSTALL_NFS=${OUTPUT_DIR}/debian/playuver-latest-linux-amd64.deb
DEB_INSTALL_PUB=${OUTPUT_DIR}/debian/playuver-stable-linux-amd64.deb
ZIP_INSTALL_PUB=${OUTPUT_DIR}/linux/playuver-stable-linux-amd64.zip

if [[ -f ${DEB_INSTALL_NFS} ]]
then
  RunEchoExit "cp ${DEB_INSTALL_NFS} /nfs/data/share/jcarreira.it.pub/apt-repo/"
fi

if [[ -f ${DEB_INSTALL_PUB} ]]
then
  RunEchoExit "scp ${DEB_INSTALL_PUB} jfmcarreira@frs.sourceforge.net:/home/frs/project/playuver/"
fi

if [[ -f ${ZIP_INSTALL_PUB} ]]
then
  RunEchoExit "scp ${ZIP_INSTALL_PUB} jfmcarreira@frs.sourceforge.net:/home/frs/project/playuver/"
fi

WINDOWS_ZIP_INSTALL_PUB=${OUTPUT_DIR}/windows/playuver-stable_wQT5_wOpenCV_wFFmpeg-Windows-amd64

if [[ -f ${WINDOWS_ZIP_INSTALL_PUB}.zip ]]
then
  cp ${WINDOWS_ZIP_INSTALL_PUB}.zip /tmp/playuver-stable-windows-amd64.zip
  cp ${WINDOWS_ZIP_INSTALL_PUB}.exe /tmp/playuver-stable-windows-amd64.exe
  RunEchoExit "scp /tmp/playuver-stable-windows-amd64.zip jfmcarreira@frs.sourceforge.net:/home/frs/project/playuver/"
  RunEchoExit "scp /tmp/playuver-stable-windows-amd64.exe jfmcarreira@frs.sourceforge.net:/home/frs/project/playuver/"
fi

WINDOWS_ZIP_INSTALL_PUB=${OUTPUT_DIR}/windows/playuver-latest_wQT5_wOpenCV_wFFmpeg-Windows-amd64

if [[ -f ${WINDOWS_ZIP_INSTALL_PUB}.zip ]]
then
  cp ${WINDOWS_ZIP_INSTALL_PUB}.zip /tmp/playuver-latest-windows-amd64.zip
  cp ${WINDOWS_ZIP_INSTALL_PUB}.exe /tmp/playuver-latest-windows-amd64.exe
  RunEchoExit "scp /tmp/playuver-latest-windows-amd64.zip jfmcarreira@frs.sourceforge.net:/home/frs/project/playuver/"
  RunEchoExit "scp /tmp/playuver-latest-windows-amd64.exe jfmcarreira@frs.sourceforge.net:/home/frs/project/playuver/"
fi
