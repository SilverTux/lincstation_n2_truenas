#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Example:
    Turn on all NVME SSD status leds and the network status led, and set a solid green led bar
        $0 -s 0,0,1,1,1,1,1 -b "rgb(0,255,0)" -m breathe

OPTIONS:
-h|--help         This help message
-s|--status-leds  Turn on or off the status leds by providing a 7-tuple of 0 or 1
                  E.g.: 1,0,0,0,0,0,0 will turn on HDD0 and turn off everything else
-b|--led-bar      Set the led bar/strip colors, the accepted format: "rgb(0,0,0)"
                  To easily pick a color use something like: https://rgbcolorpicker.com/
-m|--led-bar-mode The available modes for the led bar: solid, breathe
EOF
}

# --- Style Definitions for clear output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helper Functions for logging ---

# Prints an informational message.
# @param {string} message - The message to print.
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Prints a warning message.
# @param {string} message - The message to print.
warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Prints an error message and exits the script.
# @param {string} message - The message to print.
error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

validate_rgb() {
    local input="${LED_BAR}"
    
    if [[ $input =~ ^rgb\(([0-9]{1,3}),([0-9]{1,3}),([0-9]{1,3})\)$ ]]; then
        # Extract the three values using BASH_REMATCH
        LED_RED=${BASH_REMATCH[1]}
        LED_GREEN=${BASH_REMATCH[2]}
        LED_BLUE=${BASH_REMATCH[3]}

        # Ensure all values are within the valid range of 0-255
        if (( LED_RED >= 0 && LED_RED <= 255 && LED_GREEN >= 0 && LED_GREEN <= 255 && LED_BLUE >= 0 && LED_BLUE <= 255 )); then
            info "Valid RGB value: $input"
            return
        fi
    fi
    error "Invalid RGB format. Expected: rgb(0-255,0-255,0-255)"
}

validate_status() {
    # Validate format using regex
    if [[ ! ${STATUS_LEDS} =~ ^[0-1]+,[0-1]+,[0-1]+,[0-1]+,[0-1]+,[0-1]+,[0-1]+$ ]]; then
        error "Invalid input! Please enter exactly 7 comma-separated 0 or 1."
    fi
    
    # Split input into variables
    IFS=',' read -r HDD0 HDD1 NVME0 NVME1 NVME2 NVME3 NETWORK <<< "${STATUS_LEDS}"
}

validate_mode() {
    if [[ ${BAR_MODE} != "solid" && ${BAR_MODE} != "breathe" ]]; then
        error "Invalid led bar mode: ${BAR_MODE}! Please use solid or breathe!"
    fi
}

set_status_leds() {
    if [[ ${HDD0} == "1" ]]; then
        sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0XA0 0x04
    else
        sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0XB0 0x04
    fi

    if [[ ${HDD1} == "1" ]]; then
        sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0XA0 0x10
    else
        sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0XB0 0x10
    fi

    if [[ ${NETWORK} == "1" ]]; then
        sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0XA0 0x40
    else
        sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0XB0 0x40
    fi

    if [[ ${NVME0} == "1" ]]; then
        sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0XA1 0x01
    else
        sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0XB1 0x01
    fi

    if [[ ${NVME1} == "1" ]]; then
        sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0XA1 0x04
    else
        sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0XB1 0x04
    fi

    if [[ ${NVME2} == "1" ]]; then
        sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0XA1 0x10
    else
        sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0XB1 0x10
    fi

    if [[ ${NVME3} == "1" ]]; then
        sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0XA1 0x40
    else
        sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0XB1 0x40
    fi
}

# This function only supports solid and breath mode of the led bar
set_led_bar() {
    # LED bar modes (0 = solid, 1 = breath, 2 = loop)
    if [[ ${BAR_MODE} == "solid" ]]; then
        sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0x90 0
    elif [[ ${BAR_MODE} == "breathe" ]]; then
        sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0x90 1
    fi
    
    # LED bar brightness
    sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0x91 255 # 0-255

    # LED bar BREATH COLOR BYTE 1
    sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0x92 ${LED_RED} # 0-255
    
    # LED bar BREATH COLOR BYTE 2
    sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0x93 ${LED_GREEN} # 0-255
    
    # LED bar BREATH COLOR BYTE 3
    sudo ${I2C_BINDIR}/usr/local/sbin/i2cset -y ${found_bus} 0x26 0x94 ${LED_BLUE} # 0-255
}

while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
          usage
          shift # past value
          exit 0
          ;;
      -s|--status-leds)
          STATUS_LEDS=$2
          shift # past argument
          shift # past value
          ;;
      -b|--led-bar)
          LED_BAR=$2
          shift # past argument
          shift # past value
          ;;
      -m|--led-bar-mode)
          BAR_MODE=$2
          shift # past argument
          shift # past value
          ;;
      -*|--*)
          echo "Unknown option $1"
          usage
          exit 1
          ;;
      *)
          POSITIONAL_ARGS+=("$1") # save positional arg
          shift # past argument
          ;;
    esac
done

validate_status
validate_rgb
validate_mode

# --- Check and Load Kernel Module ---
info "Checking for the 'i2c-dev' kernel module..."
if lsmod | grep "i2c_dev"; then
    info "'i2c-dev' module is already loaded."
else
    warn "'i2c-dev' module is not loaded. Attempting to load it now..."
    sudo modprobe i2c-dev
    if lsmod | grep "i2c_dev"; then
        info "Successfully loaded the 'i2c-dev' module."
    else
        echo $?
        error "Failed to load 'i2c-dev' module. You may need to enable I2C support in your kernel configuration."
    fi
fi

# --- Build the i2c binaries in a Docker container ---
I2C_BINDIR=${PWD}/i2c_bin
sudo docker build -t lincstation_n2_leds .
sudo docker run \
    --rm \
    -v ${I2C_BINDIR}:/opt/i2c_bin \
    lincstation_n2_leds

# --- Find Device by Scanning I2C Buses ---
info "Scanning I2C buses 0-5 for a device at address 0x26..."
found_bus=-1

for i in {0..5}; do
    info "Scanning bus ${BLUE}$i${NC}..."
    echo -e "Running command: ${BLUE}sudo ${I2C_BINDIR}/usr/local/sbin/i2cdetect -y ${i}${NC}"
    # We check the output for '26', which corresponds to the address 0x26.
    if sudo ${I2C_BINDIR}/usr/local/sbin/i2cdetect -y "$i" | grep '26'; then
        info "Device found at address 0x26 on I2C bus ${BLUE}$i${NC}."
        found_bus=$i
        break
    fi
done

if [ "$found_bus" -ne -1 ]; then
    info "Successfully located device on bus: ${BLUE}${found_bus}${NC}"
else
    error "Device with address 0x26 not found on any of the scanned buses (0-5)."
fi

set_status_leds
set_led_bar
