#!/bin/bash

# Mukuvi System Terminal - Advanced System Interaction

# Logging configuration
LOG_DIR="/var/log/mukuvi"
LOG_FILE="${LOG_DIR}/mukuvi_terminal.log"

# Color configuration
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# System configuration
MUKUVI_VERSION="1.0.0"
SYSTEM_REPORT_FILE="/tmp/mukuvi_system_report.txt"

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Ensure log directory exists
    mkdir -p "$LOG_DIR"
    
    # Write to log file
    echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
}

# System health check
perform_system_health_check() {
    local report_file="$1"
    
    # Comprehensive system report
    {
        echo "MUKUVI SYSTEM HEALTH REPORT"
        echo "=========================="
        echo "Timestamp: $(date)"
        
        # CPU Information
        echo -e "\nCPU Information:"
        lscpu | grep -E 'Model name|Socket|Thread|Core|CPU MHz'
        
        # Memory Information
        echo -e "\nMemory Information:"
        free -h
        
        # Disk Usage
        echo -e "\nDisk Usage:"
        df -h
        
        # Network Interfaces
        echo -e "\nNetwork Interfaces:"
        ip addr show
        
        # Running Processes
        echo -e "\nTop 10 Processes by Memory:"
        ps aux | sort -nrk 4 | head -10
    } > "$report_file"
    
    log_message "INFO" "System health check completed"
}

# System monitoring function
monitor_system() {
    local interval="${1:-5}"
    
    echo "Starting System Monitoring (Interval: ${interval} seconds)"
    log_message "INFO" "System monitoring started"
    
    while true; do
        clear
        echo "Mukuvi System Monitor"
        echo "---------------------"
        
        # CPU Usage
        echo -e "${GREEN}CPU Usage:${NC}"
        top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}'
        
        # Memory Usage
        echo -e "\n${BLUE}Memory Usage:${NC}"
        free -h
        
        # Disk I/O
        echo -e "\n${YELLOW}Disk I/O:${NC}"
        iostat -x 1 1
        
        sleep "$interval"
    done
}

# System performance benchmark
benchmark_system() {
    echo "Running Mukuvi System Benchmark"
    log_message "INFO" "System benchmark initiated"
    
    # CPU Benchmark
    echo "CPU Benchmark:"
    time dd if=/dev/zero of=/dev/null bs=1M count=1024
    
    # Disk I/O Benchmark
    echo -e "\nDisk I/O Benchmark:"
    dd if=/dev/zero of=/tmp/benchmark bs=1M count=1024 conv=fdatasync
    
    # Network Benchmark
    echo -e "\nNetwork Benchmark:"
    ping -c 5 google.com
}

# Interactive system configuration
system_configuration() {
    local config_file="/etc/mukuvi/config"
    
    echo "Mukuvi System Configuration"
    echo "=========================="
    
    # Prompt for configuration
    read -p "Enter hostname: " new_hostname
    read -p "Enter timezone: " new_timezone
    
    # Apply configurations
    sudo hostnamectl set-hostname "$new_hostname"
    sudo timedatectl set-timezone "$new_timezone"
    
    # Save configuration
    {
        echo "HOSTNAME=${new_hostname}"
        echo "TIMEZONE=${new_timezone}"
    } | sudo tee "$config_file"
    
    log_message "CONFIG" "System configuration updated"
}

# Main terminal function
mukuvi_terminal() {
    local running=true
    
    while $running; do
        # Clear screen and display prompt
        clear
        echo -e "${BLUE}Mukuvi System Terminal v${MUKUVI_VERSION}${NC}"
        echo "Available Commands:"
        echo "  1. System Health Check"
        echo "  2. System Monitor"
        echo "  3. System Benchmark"
        echo "  4. System Configuration"
        echo "  5. Exit"
        
        # User input
        read -p "${GREEN}Enter your choice (1-5): ${NC}" choice
        
        # Command processing
        case "$choice" in
            1)
                perform_system_health_check "$SYSTEM_REPORT_FILE"
                cat "$SYSTEM_REPORT_FILE"
                read -p "Press Enter to continue..."
                ;;
            2)
                monitor_system
                ;;
            3)
                benchmark_system
                read -p "Press Enter to continue..."
                ;;
            4)
                system_configuration
                ;;
            5)
                running=false
                log_message "INFO" "Mukuvi Terminal exited"
                ;;
            *)
                echo "Invalid choice. Try again."
                sleep 2
                ;;
        esac
    done
}

# Trap signals
trap 'log_message "WARN" "Terminal interrupted"' SIGINT SIGTERM

# Start terminal
mukuvi_terminal