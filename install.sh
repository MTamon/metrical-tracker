#!/bin/bash
# Metrical Photometric Tracker installation driver.
#
# This script:
#   1. Downloads the FLAME 2020 model, FLAME texture space, FLAME masks and
#      the head template mesh (all gated behind a FLAME account).
#   2. Creates a Python 3.11 virtual environment and installs the
#      CUDA 12.8 / PyTorch 2.9.1 pin set via install_128.sh, matching
#      MTamon/smirk (release/cuda128).
#
# Preconditions:
#   - Python 3.11 is available on PATH (`python3.11 --version`).
#   - CUDA Toolkit 12.8 is installed and nvcc is on PATH or CUDA_HOME is set.
#   - gcc-11 / g++-11 are installed for building pytorch3d from source.
#   - You have a FLAME account (https://flame.is.tue.mpg.de/).

set -euo pipefail

urle () { [[ "${1}" ]] || return 1; local LANG=C i x; for (( i = 0; i < ${#1}; i++ )); do x="${1:i:1}"; [[ "${x}" == [a-zA-Z0-9.~-] ]] && echo -n "${x}" || printf '%%%02X' "'${x}"; done; echo; }
COLOR='\033[0;32m'
NC='\033[0m'

# ----------------------------------------------------------------------------
# FLAME credentials.
# ----------------------------------------------------------------------------
echo -e "\nIf you do not have an account you can register at https://flame.is.tue.mpg.de/ following the installation instruction."
read -p "Username (FLAME):" username
read -p "Password (FLAME):" password
username=$(urle "$username")
password=$(urle "$password")

# ----------------------------------------------------------------------------
# FLAME 2020 geometry.
# ----------------------------------------------------------------------------
echo -e "\n${COLOR}Downloading FLAME...${NC}"
mkdir -p data/FLAME2020/
wget --post-data "username=$username&password=$password" 'https://download.is.tue.mpg.de/download.php?domain=flame&sfile=FLAME2020.zip&resume=1' -O './FLAME2020.zip' --no-check-certificate --continue
unzip -o FLAME2020.zip -d data/FLAME2020/
rm -rf FLAME2020.zip
mv data/FLAME2020/Readme.pdf data/FLAME2020/Readme_FLAME.pdf

wget --post-data "username=$username&password=$password" 'https://download.is.tue.mpg.de/download.php?domain=flame&resume=1&sfile=TextureSpace.zip' -O './TextureSpace.zip' --no-check-certificate --continue
unzip -o TextureSpace.zip -d data/FLAME2020/
rm -rf TextureSpace.zip

wget 'https://files.is.tue.mpg.de/tbolkart/FLAME/FLAME_masks.zip' -O './FLAME_masks.zip' --no-check-certificate --continue
unzip -o FLAME_masks.zip -d data/FLAME2020/
rm -rf FLAME_masks.zip

# ----------------------------------------------------------------------------
# Head template mesh bundle.
# ----------------------------------------------------------------------------
echo -e "\n${COLOR}Downloading Mesh...${NC}"
wget -O mesh.zip "https://keeper.mpdl.mpg.de/f/f158a430ef754edba5ec/?dl=1"
unzip -o mesh.zip -d data/
mv data/mesh/* data/
rm -rf data/mesh
rm -rf mesh.zip

# ----------------------------------------------------------------------------
# Python 3.11 venv + CUDA 12.8 pin set.
# ----------------------------------------------------------------------------
echo -e "\n${COLOR}Setting up Python 3.11 virtual environment...${NC}"
if ! command -v python3.11 >/dev/null 2>&1; then
    echo "[install.sh] python3.11 is required but was not found on PATH."
    echo "[install.sh] Install it (e.g. Ubuntu 22.04: 'sudo apt install python3.11 python3.11-venv')"
    echo "[install.sh] and rerun this script."
    exit 1
fi

VENV_DIR="${VENV_DIR:-.venv}"
if [ ! -d "${VENV_DIR}" ]; then
    python3.11 -m venv "${VENV_DIR}"
fi
# shellcheck disable=SC1090
source "${VENV_DIR}/bin/activate"

echo -e "\n${COLOR}Installing CUDA 12.8 / PyTorch 2.9.1 pin set (install_128.sh)...${NC}"
bash "$(dirname "$0")/install_128.sh"

echo -e "\n${COLOR}Installation has finished!${NC}"
echo -e "Activate the environment with: source ${VENV_DIR}/bin/activate"
