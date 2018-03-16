#!/bin/bash

# Get the directory this script is in
pushd `dirname $0` > /dev/null
SCRIPTPATH=$(pwd -P)
popd > /dev/null

LOG_OUTPUT=/tmp/calyp_build_out
TMPDIR=/tmp/calyp-build

OUTPUT_DIR=/nfs/data/share/Calyp

VERSION=0.14.1

COUNT=-1; BRANCH_TYPES= ; BRANCH_TYPES_NAMES= ; CMAKE_CFG_BRANCH= ;
# let COUNT+=1; BRANCH_TYPES[$COUNT]="stable"; BRANCH_TYPES_NAMES[$COUNT]="stable"; DEB_NAMES[$COUNT]=""; CMAKE_CFG_BRANCH[$COUNT]="-DRELEASE_BUILD=ON"
let COUNT+=1; BRANCH_TYPES[$COUNT]="master"; BRANCH_TYPES_NAMES[$COUNT]="latest"; DEB_NAMES[$COUNT]="-latest"; CMAKE_CFG_BRANCH[$COUNT]="-DRELEASE_BUILD=OFF"
BRANCH_COUNT=$COUNT

COUNT=-1; CONDITION_TYPES= ; CONDITION_TYPES_NAMES= ;
let COUNT+=1; DEPLOY_COND[$COUNT]="1"; CONDITION_TYPES[$COUNT]="-DUSE_FFMPEG=ON -DUSE_OPENCV=ON -DUSE_QT4=OFF"; CONDITION_TYPES_NAMES[$COUNT]="wFFmpeg_wOpenCV_wQT5"
CONDITION_COUNT=$COUNT


function RunEchoExit() {
  echo "$@"
  eval $@
  if [ $? -ne 0 ]; then
    echo "Error in last command"
    exit
  fi
}

cd $SCRIPTPATH

BUILD_LINUX=1

if [[ $BUILD_LINUX -eq 1 ]]
then

for BRANCH_IDX in  $(seq 0 ${BRANCH_COUNT}); do

  BRANCH=${BRANCH_TYPES[BRANCH_IDX]}

  RunEchoExit "git -C calyp checkout $BRANCH"
  RunEchoExit "git -C calyp pull"

  for COND_IDX in $(seq 0 ${CONDITION_COUNT}); do

    CMAKE_CFG="-DUPDATE_CHANNEL=${BRANCH_TYPES_NAMES[BRANCH_IDX]} ${CMAKE_CFG_BRANCH[BRANCH_IDX]} ${CONDITION_TYPES[COND_IDX]} "

    [[ -d ${TMPDIR} ]] && rm -R ${TMPDIR}
    mkdir ${TMPDIR}
    cd ${TMPDIR}
    RunEchoExit "cmake -DCMAKE_BUILD_TYPE=Release -DPACKAGE_NAME=${BRANCH_TYPES_NAMES[BRANCH_IDX]} $CMAKE_CFG $SCRIPTPATH"
    VERSION=$(cmake $SCRIPTPATH |& grep Version | awk '{print $3}')
    RunEchoExit "make -j"
    RunEchoExit "make package"
    cd $SCRIPTPATH

    if [[ ${DEPLOY_COND[COND_IDX]} ]]
    then
      if [[ ${BRANCH_TYPES_NAMES[BRANCH_IDX]} == "stable" ]]
      then
        UPLOAD_NAME=${VERSION}
        mkdir -p ${OUTPUT_DIR}/linux/${VERSION}
        cp $( find ${TMPDIR} -maxdepth 1 -iname "*.zip" ) ${OUTPUT_DIR}/linux/${VERSION}/calyp-${UPLOAD_NAME}-linux-amd64.zip

        RunEchoExit "rsync -avP ${OUTPUT_DIR}/linux/${VERSION} jfmcarreira@frs.sourceforge.net:/home/frs/project/playuver/"
      fi
      UPLOAD_NAME=${BRANCH_TYPES_NAMES[BRANCH_IDX]}
      cp $( find ${TMPDIR} -maxdepth 1 -iname "*.deb" ) ${OUTPUT_DIR}/debian/calyp-${UPLOAD_NAME}-linux-amd64.deb
      cp $( find ${TMPDIR} -maxdepth 1 -iname "*.zip" ) ${OUTPUT_DIR}/linux/calyp-${UPLOAD_NAME}-linux-amd64.zip
      RunEchoExit "scp ${OUTPUT_DIR}/debian/calyp-${UPLOAD_NAME}-linux-amd64.deb jfmcarreira@frs.sourceforge.net:/home/frs/project/playuver/"
      RunEchoExit "scp ${OUTPUT_DIR}/linux/calyp-${UPLOAD_NAME}-linux-amd64.zip jfmcarreira@frs.sourceforge.net:/home/frs/project/playuver/"
    fi

    rm -R ${TMPDIR}

  done
done
fi

WINDOWS_INSTALL_VERSION="wQT5_wOpenCV_wFFmpeg"
BRANCH_LIST="stable latest"
for BRANCH in ${BRANCH_LIST}
do
  cp ${OUTPUT_DIR}/windows/calyp-${BRANCH}_${WINDOWS_INSTALL_VERSION}-Windows-amd64.zip ${OUTPUT_DIR}/windows/calyp-${BRANCH}-windows-amd64.zip
  cp ${OUTPUT_DIR}/windows/calyp-${BRANCH}_${WINDOWS_INSTALL_VERSION}-Windows-amd64.exe ${OUTPUT_DIR}/windows/calyp-${BRANCH}-windows-amd64-installer.exe

  RunEchoExit "scp ${OUTPUT_DIR}/windows/calyp-${BRANCH}-windows-amd64.zip jfmcarreira@frs.sourceforge.net:/home/frs/project/playuver/"
  RunEchoExit "scp ${OUTPUT_DIR}/windows/calyp-${BRANCH}-windows-amd64-installer.exe jfmcarreira@frs.sourceforge.net:/home/frs/project/playuver/"
done

