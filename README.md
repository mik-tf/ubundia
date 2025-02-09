<h1> Ubundia - Ubuntu NVIDIA GPU Setup Tool</h1>

<h2> Table of Contents</h2>

- [Introduction](#introduction)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Manual Installation](#manual-installation)
  - [Using Make](#using-make)
  - [On the ThreeFold Grid](#on-the-threefold-grid)
- [Usage](#usage)
- [Commands](#commands)
- [Examples](#examples)
- [Logging](#logging)
- [License](#license)
- [Support](#support)

## Introduction

Ubundia is a comprehensive GPU setup tool for Ubuntu systems with NVIDIA graphics cards. It automates the installation and configuration of NVIDIA drivers and CUDA toolkit, making GPU setup simple and reliable.

## Features

- Automated NVIDIA driver installation
- CUDA toolkit setup
- System compatibility checks
- Detailed logging system
- GPU status monitoring
- Interactive installation process
- Command-line interface
- Secure execution model

## Requirements

- Ubuntu operating system
- NVIDIA GPU
- Sudo privileges
- Internet connection
- Basic system utilities

## Installation

### Manual Installation

```bash
# Download
wget https://raw.githubusercontent.com/mik-tf/ubundia/main/ubundia.sh

# Install
bash ubundia.sh install

# Remove installer
rm ubundia.sh
```

### Using Make

The project includes a Makefile for easier management. Available make commands:

```bash
# First clone the repository
git clone https://github.com/mik-tf/ubundia.git
cd ubundia

# Install the tool
make build

# Reinstall (uninstall then install)
make rebuild

# Remove the installation
make delete
```

The Makefile commands do the following:
- `make build`: Installs the script system-wide
- `make rebuild`: Removes existing installation and reinstalls
- `make delete`: Removes the installation completely

### On the ThreeFold Grid

You can use this script to set up a GPU node on the ThreeFold Grid:

- Deploy full VM (dedicated node) with NVIDIA GPU
- Install prerequisites:
  ```
  apt update && apt install -y git make sudo
  ```
- Clone, install the tool and run it
  ```
  git clone https://github.com/mik-tf/ubundia
  cd ubundia
  make
  ubundia build
  ```

## Usage

Run the command with no arguments to see help:
```bash
ubundia
```

## Commands

- `build` - Run full GPU setup
- `status` - Show GPU status
- `install` - Install script system-wide
- `uninstall` - Remove script from system
- `logs` - Show full logs
- `recent-logs [n]` - Show last n lines of logs
- `delete-logs` - Delete all logs
- `help` - Show help message
- `version` - Show version information

## Examples

```bash
# Run full setup
ubundia build

# Check GPU status
ubundia status

# View logs
ubundia logs

# Show recent logs
ubundia recent-logs 100
```

## Logging

Logs are stored in `/var/log/ubundia/` with the following features:
- Installation logging
- Error tracking
- Status updates
- Timestamp information
- Log rotation
- Cleanup utilities

## License

Apache License 2.0

## Support

For issues and questions:
[GitHub Repository](https://github.com/mik-tf/ubundia)