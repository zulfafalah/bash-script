# Bash Script Collection# Multi-Service Startup Script



A collection of useful bash scripts for automating various tasks, from Docker maintenance to multi-service management.A simple bash script to run multiple Go microservices simultaneously in separate terminal tabs.



## Description## Description



This repository contains custom bash scripts designed to simplify common development and system administration tasks. Each script is documented with usage instructions and examples.This script allows you to start an entire Go microservices ecosystem with a single command. The script will open separate terminal tabs for each service, making monitoring and debugging easier.



---## Services Running



## 📜 Available ScriptsThis script will run 6 Go services + 1 frontend:



### 1. Docker Image Cleanup (`clean_up_docker_image.sh`)1. **Service Collection** - `~/Development/GOLANG/service-collection`

2. **Service Proxy** - `~/Development/GOLANG/service-proxy` 

Automatically removes unused Docker images that are older than a specified number of months, helping to free up disk space.3. **Service Master** - `~/Development/GOLANG/service-master`

4. **Service Identity Access** - `~/Development/GOLANG/service-identity-access`

#### Features5. **Service Print** - `~/Development/GOLANG/service-print`

- Removes Docker images older than X months (default: 3 months)6. **Service Storage** - `~/Development/GOLANG/service-storage`

- Only deletes images not being used by any containers7. **Service Proxy Frontend** - `~/Development/GOLANG/service-proxy/public` (npm dev server)

- Shows image age and size before deletion

- Interactive confirmation before deletion## Prerequisites

- Optional build cache cleanup

- Displays disk space before and after cleanup- Linux with GNOME Terminal

- Go installed on the system

#### Prerequisites- Node.js and npm for frontend

- Docker installed and running- All service directories must exist in the specified locations

- Sufficient permissions to run Docker commands

## Usage

#### Usage

### Running the Script

```bash

# Give execute permission```bash

chmod +x clean_up_docker_image.sh# Give execute permission

chmod +x start_service.sh

# Run with default (3 months)

./clean_up_docker_image.sh# Run the script

./start_service.sh

# Remove images older than 6 months```

./clean_up_docker_image.sh 6

### Stopping Services

# Remove images older than 1 month

./clean_up_docker_image.sh 1- **Method 1**: Press `Ctrl+C` in the main terminal to stop all services at once

- **Method 2**: Press `Enter` to run services in background, then use `Ctrl+C` later

# Show help- **Method 3**: Close terminal tabs manually

./clean_up_docker_image.sh --help
```

#### Example Output
```
=== Docker Image Cleanup Script ===
Mencari images yang tidak dipakai lebih dari 3 bulan...

✓ Akan dihapus: myapp:old (245MB) - Umur: 4 bulan (120 hari)
✓ Akan dihapus: testimg:v1 (512MB) - Umur: 5 bulan (150 hari)
✗ Dilewati (masih dipakai): nginx:latest

════════════════════════════════════════════════════
Total images yang akan dihapus: 2
Kriteria: Tidak dipakai dan umur > 3 bulan
════════════════════════════════════════════════════

Lanjutkan menghapus images? (y/n):
```

---

### 2. Multi-Service Startup (`start_service.sh`)

Launches multiple Go microservices simultaneously in separate terminal tabs for easy monitoring and debugging.

#### Features
- Starts multiple services with a single command
- Opens each service in a separate terminal tab
- Automatic cleanup when script is terminated
- Monitors all service processes
- Easy to stop all services at once

#### Services Running
This script launches 6 Go services + 1 frontend:

1. **Service Collection** - `~/Development/GOLANG/service-collection`
2. **Service Proxy** - `~/Development/GOLANG/service-proxy` 
3. **Service Master** - `~/Development/GOLANG/service-master`
4. **Service Identity Access** - `~/Development/GOLANG/service-identity-access`
5. **Service Print** - `~/Development/GOLANG/service-print`
6. **Service Storage** - `~/Development/GOLANG/service-storage`
7. **Service Proxy Frontend** - `~/Development/GOLANG/service-proxy/public` (npm dev server)

#### Prerequisites
- Linux with GNOME Terminal
- Go installed on the system
- Node.js and npm for frontend
- All service directories must exist in the specified locations

#### Usage

```bash
# Give execute permission
chmod +x start_service.sh

# Run the script
./start_service.sh
```

#### Stopping Services

- **Method 1**: Press `Ctrl+C` in the main terminal to stop all services at once
- **Method 2**: Press `Enter` to run services in background, then use `Ctrl+C` later
- **Method 3**: Close terminal tabs manually

---

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/zulfafalah/bash-script.git
cd bash-script

# Make scripts executable
chmod +x *.sh

# Run any script
./script_name.sh [arguments]
```

---

## 📝 Contributing

Feel free to contribute by:
1. Adding new useful bash scripts
2. Improving existing scripts
3. Reporting bugs or issues
4. Suggesting new features

---

## 📄 License

This project is open source and available for personal and commercial use.

---

## 👤 Author

**Zulfa Falah**

- GitHub: [@zulfafalah](https://github.com/zulfafalah)

---

## 💡 Tips

- Always review scripts before running them
- Test scripts in a safe environment first
- Keep scripts updated with your system changes
- Add your own custom scripts to this collection
