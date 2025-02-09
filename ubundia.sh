#!/bin/bash

# GPU Setup Script for Ubuntu
# License: Apache 2.0

# Get script name dynamically
SCRIPT_PATH="$0"
SCRIPT_NAME=$(basename "$SCRIPT_PATH")
INSTALL_NAME=$(basename "$SCRIPT_NAME" .sh)

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging configuration
LOG_DIR="/var/log/${INSTALL_NAME}"
INSTALL_LOG="${LOG_DIR}/install.log"

# Version
VERSION="0.1.0"

# Helper Functions
log() {
    echo -e "${GREEN}[SETUP]${NC} $1"
    if [ -w "$INSTALL_LOG" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$INSTALL_LOG"
    fi
    sleep 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    if [ -w "$INSTALL_LOG" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$INSTALL_LOG"
    fi
    sleep 1
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    if [ -w "$INSTALL_LOG" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$INSTALL_LOG"
    fi
    sleep 1
    exit 1
}

setup_logging() {
    # Create log directory with sudo
    if [ ! -d "$LOG_DIR" ]; then
        sudo mkdir -p "$LOG_DIR" || error "Failed to create log directory"
    fi

    # Create log file if it doesn't exist
    if [ ! -f "$INSTALL_LOG" ]; then
        sudo touch "$INSTALL_LOG" || error "Failed to create log file"
    fi

    # Set proper ownership and permissions
    sudo chown $USER:$USER "$LOG_DIR" || error "Failed to set log directory ownership"
    sudo chown $USER:$USER "$INSTALL_LOG" || error "Failed to set log file ownership"
    sudo chmod 755 "$LOG_DIR" || error "Failed to set log directory permissions"
    sudo chmod 644 "$INSTALL_LOG" || error "Failed to set log file permissions"
}

show_logs() {
    if [ ! -f "$INSTALL_LOG" ]; then
        echo -e "${YELLOW}No logs found at: $INSTALL_LOG${NC}"
        return 1
    fi

    echo -e "${BLUE}===== Log File Contents ($INSTALL_LOG) =====${NC}"
    echo -e "${BLUE}Last modified: $(stat -c %y "$INSTALL_LOG")${NC}"
    echo -e "${BLUE}File size: $(du -h "$INSTALL_LOG" | cut -f1)${NC}"
    echo -e "${BLUE}============================================${NC}\n"

    if command -v less &> /dev/null; then
        less -R "$INSTALL_LOG"
    else
        cat "$INSTALL_LOG"
    fi
}

show_recent_logs() {
    local lines=${1:-50}
    
    if [ ! -f "$INSTALL_LOG" ]; then
        echo -e "${YELLOW}No logs found at: $INSTALL_LOG${NC}"
        return 1
    fi

    echo -e "${BLUE}===== Recent Logs (Last $lines lines) =====${NC}"
    echo -e "${BLUE}Last modified: $(stat -c %y "$INSTALL_LOG")${NC}"
    echo -e "${BLUE}============================================${NC}\n"

    tail -n "$lines" "$INSTALL_LOG"
}

delete_logs() {
    echo -e "${YELLOW}Deleting logs...${NC}"
    if [ -d "$LOG_DIR" ]; then
        if ! sudo rm -rf "$LOG_DIR"; then
            error "Failed to delete log directory: $LOG_DIR"
        else
            echo -e "${GREEN}Successfully deleted log directory: $LOG_DIR${NC}"
        fi
    else
        echo -e "${YELLOW}Log directory does not exist: $LOG_DIR${NC}"
    fi
}

install_prerequisites_and_dependencies() {

    # Check for Ubuntu
    if ! grep -q "Ubuntu" /etc/os-release; then
        warn "This script is designed for Ubuntu. Other distributions may not work correctly."
    fi

    # Update package lists
    log "Updating package lists..."
    if ! sudo apt update; then
        error "Failed to update package lists"
    fi

    # Define all required packages
    local PACKAGES=(
        "wget"
        "curl"
        "pciutils"
        "build-essential"
        "software-properties-common"
        "ubuntu-drivers-common"
        "dkms"
        "linux-headers-$(uname -r)"
    )

    # Check and install packages only if they're not already installed
    for package in "${PACKAGES[@]}"; do
        if ! dpkg -l | grep -q "^ii.*$package"; then
            log "Installing $package..."
            if ! sudo apt install -y "$package"; then
                warn "Failed to install $package"
            fi
        else
            log "$package is already installed"
        fi
    done

    # Optionally perform system upgrade
    if [ "${PERFORM_UPGRADE:-false}" = true ]; then
        log "Performing system upgrade..."
        if ! sudo apt upgrade -y; then
            warn "Package upgrade failed, continuing anyway..."
        fi
    fi
}

setup_gpu() {
    log "Checking GPU and drivers..."
    
    if ! lspci | grep -i nvidia > /dev/null; then
        error "No NVIDIA GPU detected in this system!"
    fi

    log "NVIDIA GPU detected. Checking current setup..."

    # Check current driver status
    if nvidia-smi &>/dev/null; then
        CURRENT_DRIVER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
        log "NVIDIA drivers are already installed (Version: $CURRENT_DRIVER)"
    else
        log "Installing NVIDIA drivers..."
        if ! sudo ubuntu-drivers autoinstall; then
            error "Failed to install NVIDIA drivers"
        fi
        log "Drivers installed. A system restart will be required."
    fi

    # Check CUDA installation
    if ! command -v nvcc &>/dev/null; then
        log "Installing CUDA toolkit..."
        if ! sudo apt install -y nvidia-cuda-toolkit; then
            error "Failed to install CUDA toolkit"
        fi
        CUDA_VERSION=$(nvcc --version | grep "release" | awk '{print $5}' | sed 's/,//')
        log "CUDA toolkit installed (Version: $CUDA_VERSION)"
    else
        CUDA_VERSION=$(nvcc --version | grep "release" | awk '{print $5}' | sed 's/,//')
        log "CUDA toolkit is already installed (Version: $CUDA_VERSION)"
    fi
}

show_gpu_info() {
    echo -e "\n${BLUE}===== GPU Information =====${NC}"
    
    echo -e "\n${GREEN}GPU Hardware Details:${NC}"
    lspci | grep -i nvidia
    
    echo -e "\n${GREEN}NVIDIA Driver Details:${NC}"
    if nvidia-smi &>/dev/null; then
        nvidia-smi
    else
        echo "NVIDIA drivers not loaded"
    fi
    
    echo -e "\n${GREEN}CUDA Version:${NC}"
    if command -v nvcc &>/dev/null; then
        nvcc --version
    else
        echo "CUDA not installed"
    fi
}

install() {
    echo -e "${GREEN}Installing ${INSTALL_NAME} v${VERSION}...${NC}"
    if ! sudo -v; then
        error "Failed to obtain sudo privileges"
    fi

    # Remove existing installation if any
    sudo rm -f "/usr/local/bin/${INSTALL_NAME}"
    
    # Install the script
    if ! sudo cp "$SCRIPT_PATH" "/usr/local/bin/${INSTALL_NAME}"; then
        error "Failed to copy script to /usr/local/bin"
    fi

    if ! sudo chown root:root "/usr/local/bin/${INSTALL_NAME}"; then
        error "Failed to set script ownership"
    fi

    if ! sudo chmod 755 "/usr/local/bin/${INSTALL_NAME}"; then
        error "Failed to set script permissions"
    fi

    # Create log directory with proper permissions
    sudo mkdir -p "$LOG_DIR"
    sudo chown $USER:$USER "$LOG_DIR"
    sudo chmod 755 "$LOG_DIR"

    echo -e "\n${PURPLE}${INSTALL_NAME} v${VERSION} has been installed successfully.${NC}"
    echo -e "\nTo see available commands, run: ${BLUE}${INSTALL_NAME} help${NC}"
}

uninstall() {
    echo -e "${GREEN}Uninstalling ${INSTALL_NAME}...${NC}"
    if ! sudo -v; then
        error "Failed to obtain sudo privileges"
    fi

    # Remove the script
    if ! sudo rm -f "/usr/local/bin/${INSTALL_NAME}"; then
        error "Failed to remove script from /usr/local/bin"
    fi
    
    # Remove logs
    delete_logs
    
    echo -e "${GREEN}Uninstallation completed successfully.${NC}"
}

show_status() {
    clear
    echo -e
    echo -e "${BLUE}===== GPU Status (${INSTALL_NAME} v${VERSION}) =====${NC}"
    echo -e
    show_gpu_info
}

show_help() {
    echo -e
    echo -e "${BLUE}===== ${INSTALL_NAME} v${VERSION} Help =====${NC}"
    echo -e "Usage: ${INSTALL_NAME} [COMMAND]"
    echo -e
    echo "License:"
    echo "- Apache 2.0"
    echo -e
    echo "Repository:"
    echo "- https://github.com/mik-tf/ubundia"
    echo -e
    echo "Commands:"
    echo -e "${GREEN}  build${NC}           - Run full GPU setup"
    echo -e "${GREEN}  status${NC}          - Show GPU status"
    echo -e "${GREEN}  install${NC}         - Install script system-wide"
    echo -e "${GREEN}  uninstall${NC}       - Remove script from system"
    echo -e "${GREEN}  logs${NC}            - Show full logs"
    echo -e "${GREEN}  recent-logs [n]${NC} - Show last n lines of logs (default: 50)"
    echo -e "${GREEN}  delete-logs${NC}     - Delete all logs"
    echo -e "${GREEN}  help${NC}            - Show this help message"
    echo -e "${GREEN}  version${NC}         - Show version information"
    echo
    echo "Examples:"
    echo "  ${INSTALL_NAME} build            # Run full GPU setup"
    echo "  ${INSTALL_NAME} status           # Show GPU status"
    echo "  ${INSTALL_NAME} logs             # Show all logs"
    echo "  ${INSTALL_NAME} recent-logs 100  # Show last 100 log lines"
    echo "  ${INSTALL_NAME} delete-logs      # Delete all logs"
    echo
    echo "Requirements:"
    echo "- Ubuntu system"
    echo "- NVIDIA GPU"
    echo "- Sudo privileges"
    echo -e
}

show_version() {
    echo -e "${BLUE}${INSTALL_NAME} v${VERSION}${NC}"
}

main() {
    clear
    echo -e "${BLUE}===== GPU Setup Script v${VERSION} =====${NC}"
    
    install_prerequisites_and_dependencies
    setup_logging
    setup_gpu
    show_gpu_info
    
    echo -e "\n${GREEN}Setup complete!${NC}"
    if ! nvidia-smi &>/dev/null; then
        echo -e "${YELLOW}Please restart your system to complete the driver installation.${NC}"
    fi
}

# Command handling
handle_command() {
    case "$1" in
        "status")
            show_status
            ;;
        "install")
            install
            ;;
        "uninstall")
            uninstall
            ;;
        "logs")
            show_logs
            ;;
        "recent-logs")
            show_recent_logs "${2:-50}"
            ;;
        "delete-logs")
            delete_logs
            ;;
        "help"|"")
            show_help
            ;;
        "version")
            show_version
            ;;
        "build")
            main
            ;;
        *)
            echo -e "${RED}Unknown command: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    trap 'echo -e "\n${RED}Script interrupted${NC}"; exit 1' SIGINT SIGTERM
    handle_command "$1" "$2"
fi