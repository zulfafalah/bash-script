#!/bin/bash

# Script to start multiple Go services in separate terminal tabs
echo "Starting Go services in separate terminal tabs..."

# Array to store terminal PIDs
declare -a TERMINAL_PIDS=()

# Function to cleanup all terminals when script exits
cleanup() {
    echo ""
    echo "Stopping all services..."
    for pid in "${TERMINAL_PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            echo "Stopping terminal with PID: $pid"
            kill -TERM "$pid" 2>/dev/null
        fi
    done
    echo "All services stopped."
    exit 0
}

# Set trap to call cleanup function on script termination
trap cleanup SIGINT SIGTERM EXIT

# Start service-collection in a new terminal tab
gnome-terminal --tab --title="Service Collection" -- bash -c "
    echo 'Starting Service Collection...'
    cd ~/Development/GOLANG/service-collection
    go run cmd/web/main.go
    exec bash
" &
TERMINAL_PIDS+=($!)

# Start service-proxy in another new terminal tab
gnome-terminal --tab --title="Service Proxy" -- bash -c "
    echo 'Starting Service Proxy...'
    cd ~/Development/GOLANG/service-proxy
    go run main.go
    exec bash
" &
TERMINAL_PIDS+=($!)

# Start service-master in another new terminal tab
gnome-terminal --tab --title="Service Master" -- bash -c "
    echo 'Starting Service Master...'
    cd ~/Development/GOLANG/service-master
    go run cmd/web/main.go
    exec bash
" &
TERMINAL_PIDS+=($!)

# Start service-identity-access in another new terminal tab
gnome-terminal --tab --title="Service Identity Access" -- bash -c "
    echo 'Starting Service Identity Access...'
    cd ~/Development/GOLANG/service-identity-access
    go run main.go
    exec bash
" &
TERMINAL_PIDS+=($!)

# Start service-print in another new terminal tab
gnome-terminal --tab --title="Service Print" -- bash -c "
    echo 'Starting Service Print...'
    cd ~/Development/GOLANG/service-print
    go run cmd/web/main.go
    exec bash
" &
TERMINAL_PIDS+=($!)

# Start service-storage in another new terminal tab
gnome-terminal --tab --title="Service Storage" -- bash -c "
    echo 'Starting Service Storage...'
    cd ~/Development/GOLANG/service-storage
    go run cmd/web/main.go
    exec bash
" &
TERMINAL_PIDS+=($!)

# Start service-proxy frontend in another new terminal tab
gnome-terminal --tab --title="Service Proxy Frontend" -- bash -c "
    echo 'Starting Service Proxy Frontend...'
    cd ~/Development/GOLANG/service-proxy/public
    npm run dev
    exec bash
" &
TERMINAL_PIDS+=($!)

echo "All services (6 Go services + 1 frontend) started in separate terminal tabs!"
echo "Terminal PIDs: ${TERMINAL_PIDS[*]}"
echo ""
echo "Press Ctrl+C to stop all services, or press Enter to keep them running in background..."

# Wait for user input or signal
read -r

# End of script