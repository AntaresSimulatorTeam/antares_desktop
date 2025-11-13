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

echo "INFO: Generating the Desktop version of the Web Application..."
if [[ "$OSTYPE" == "msys"* ]]; then
  pushd ${PROJECT_DIR}
  pyinstaller --distpath ${DIST_DIR} AntaresWebWin.spec
  popd
else
  pushd ${PROJECT_DIR}
  pyinstaller --distpath ${DIST_DIR} AntaresWebLinux.spec
  popd
fi

echo "INFO: Creating destination directory '${ANTARES_SOLVER_DIR}'..."
mkdir -p "${ANTARES_SOLVER_DIR}"

echo "INFO: Copying basic configuration files..."
cp -r "${RESOURCES_DIR}"/antares-desktop-fs/* "${DIST_DIR}"

declare -A VERSION_MAP=(
    ["8.8.17"]="8_8"
    ["9.2.2"]="9_2"
    ["9.3.1"]="9_3"
)

declare -A YAML_VERSION_MAP=(
  ["8.8.17"]="880"
  ["9.2.2"]="920"
  ["9.3.1"]="930"
)

SOLVER_MAPPING_IN_CONFIG_FILE=""

for KEY in "${!VERSION_MAP[@]}"; do
  LINK="https://github.com/AntaresSimulatorTeam/Antares_Simulator/releases/download/v$KEY/$ANTARES_SOLVER_ZIPFILE_NAME"
  FOLDER_NAME="${VERSION_MAP[$KEY]}"
  YAML_SOLVER_NAME="${YAML_VERSION_MAP[$KEY]}"

  if [[ "$FOLDER_NAME" == "8_8" ]]; then
    SOLVER_PATH="-8.8"
  else
    SOLVER_PATH=""
  fi

  mkdir -p "${ANTARES_SOLVER_DIR}/${VERSION_MAP[$KEY]}"
  cd "${ANTARES_SOLVER_DIR}/${VERSION_MAP[$KEY]}" || exit
  wget "$LINK"
  echo "INFO: Uncompressing '$ANTARES_SOLVER_ZIPFILE_NAME'..."
  if [[ "$OSTYPE" == "msys"* ]]; then
    7z x $ANTARES_SOLVER_ZIPFILE_NAME
    echo "INFO: Moving executables in '$ANTARES_SOLVER_DIR'..."
    mv "$ANTARES_SOLVER_DIR/solver/Release/"* "$ANTARES_SOLVER_DIR"
    rm -rf $"$ANTARES_SOLVER_DIR/solver/Release/"
    SOLVER_NAME="antares$SOLVER_PATH-solver.exe"
  else
    tar xzf $ANTARES_SOLVER_ZIPFILE_NAME
    SOLVER_NAME="antares$SOLVER_PATH-solver"
  fi
  SOLVER_MAPPING_IN_CONFIG_FILE+="        $YAML_SOLVER_NAME: .\/AntaresWeb\/antares_solver\/$FOLDER_NAME\/$SOLVER_NAME\n"
  rm $ANTARES_SOLVER_ZIPFILE_NAME
  cd ..
done

echo "Writing solver mapping inside the application config file"
sed -i "/VER: ANTARES_SOLVER_PATH/c\\$SOLVER_MAPPING_IN_CONFIG_FILE" "${DIST_DIR}/config.yaml"

echo "INFO: Creating shortcuts..."
if [[ "$OSTYPE" == "msys"* ]]; then
  cp "${RESOURCES_DIR}/AntaresWebServerShortcut.lnk" "${DIST_DIR}"
else
  echo "INFO: Updating executable permissions..."
  chmod +x "${DIST_DIR}/AntaresWeb/AntaresWebServer"
fi

echo "INFO: Antares Web Packaging DONE."
