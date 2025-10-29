# Multi-Service Startup Script

A simple bash script to run multiple Go microservices simultaneously in separate terminal tabs.

## Description

This script allows you to start an entire Go microservices ecosystem with a single command. The script will open separate terminal tabs for each service, making monitoring and debugging easier.

## Services Running

This script will run 6 Go services + 1 frontend:

1. **Service Collection** - `~/Development/GOLANG/service-collection`
2. **Service Proxy** - `~/Development/GOLANG/service-proxy` 
3. **Service Master** - `~/Development/GOLANG/service-master`
4. **Service Identity Access** - `~/Development/GOLANG/service-identity-access`
5. **Service Print** - `~/Development/GOLANG/service-print`
6. **Service Storage** - `~/Development/GOLANG/service-storage`
7. **Service Proxy Frontend** - `~/Development/GOLANG/service-proxy/public` (npm dev server)

## Prerequisites

- Linux with GNOME Terminal
- Go installed on the system
- Node.js and npm for frontend
- All service directories must exist in the specified locations

## Usage

### Running the Script

```bash
# Give execute permission
chmod +x start_service.sh

# Run the script
./start_service.sh
```

### Stopping Services

- **Method 1**: Press `Ctrl+C` in the main terminal to stop all services at once
- **Method 2**: Press `Enter` to run services in background, then use `Ctrl+C` later
- **Method 3**: Close terminal tabs manually
