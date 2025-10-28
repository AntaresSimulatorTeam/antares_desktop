#!/bin/bash

# Antares Web Packaging -- Desktop Version
#
# This script is launch by the GitHub Workflow `.github/workflows/deploy.yml`.
# It builds the Desktop version of the Web Application.
# Make sure you run the `npm install` stage before running this script.

set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
PROJECT_DIR=$(dirname -- "${SCRIPT_DIR}")
DIST_DIR="${PROJECT_DIR}/dist/package"
RESOURCES_DIR="${PROJECT_DIR}/resources"
ANTARES_SOLVER_DIR="${DIST_DIR}/AntaresWeb/antares_solver"

if [[ "$OSTYPE" == "msys"* ]]; then
  ANTARES_SOLVER_FOLDER_NAME="antares-solver_windows"
  ANTARES_SOLVER_ZIPFILE_NAME="$ANTARES_SOLVER_FOLDER_NAME.zip"
else
  ANTARES_SOLVER_ZIPFILE_NAME="antares-solver_ubuntu22.04.tar.gz"
fi

echo "INFO: Preparing the Git Commit ID..."
git log -1 HEAD --format=%H > ${RESOURCES_DIR}/commit_id

echo "INFO: Remove the previous build if any..."
# Avoid the accumulation of files from previous builds (in development).
rm -rf ${DIST_DIR}

echo "INFO: Creating destination directory '${ANTARES_SOLVER_DIR}'..."
mkdir -p "${ANTARES_SOLVER_DIR}"

declare -A VERSION_MAP=(
    ["8.8.17"]="8_8"
    ["9.2.2"]="9_2"
    ["9.3.1"]="9_3"
)

for KEY in "${!VERSION_MAP[@]}"; do
  LINK="https://github.com/AntaresSimulatorTeam/Antares_Simulator/releases/download/v$KEY/$ANTARES_SOLVER_ZIPFILE_NAME"
  FOLDER_NAME="${VERSION_MAP[$KEY]}"
  mkdir -p "${ANTARES_SOLVER_DIR}/${VERSION_MAP[$KEY]}"
  cd "${ANTARES_SOLVER_DIR}/${VERSION_MAP[$KEY]}" || exit
  wget "$LINK"
  cd ..
done

echo "INFO: Copying basic configuration files..."
rm -rf "${DIST_DIR}/examples" # in case of replay
cp -r "${RESOURCES_DIR}"/antares-desktop-fs/* "${DIST_DIR}"
if [[ "$OSTYPE" == "msys"* ]]; then
  sed -i "s/VER: ANTARES_SOLVER_PATH/$ANTARES_SOLVER_VERSION_INT: .\/AntaresWeb\/antares_solver\/antares-$ANTARES_SOLVER_VERSION-solver.exe/g" "${DIST_DIR}/config.yaml"
else
  sed -i "s/VER: ANTARES_SOLVER_PATH/$ANTARES_SOLVER_VERSION_INT: .\/AntaresWeb\/antares_solver\/antares-$ANTARES_SOLVER_VERSION-solver/g" "${DIST_DIR}/config.yaml"
fi

echo "INFO: Antares Web Packaging DONE."
