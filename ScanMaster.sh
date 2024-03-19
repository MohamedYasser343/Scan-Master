#!/bin/bash

echo "
                                                                                                
                                                                                                
  ____                                     ___       ___                                        
 6MMMMb\                                   \`MMb     dMM'                                        
6M'    \`                                    MMM.   ,PMM                    /                    
MM         ____      ___   ___  __          M\`Mb   d'MM    ___     ____   /M      ____  ___  __ 
YM.       6MMMMb.  6MMMMb  \`MM 6MMb         M YM. ,P MM  6MMMMb   6MMMMb\\/MMMMM  6MMMMb \`MM 6MM 
 YMMMMb  6M'   Mb 8M'  \`Mb  MMM9 \`Mb        M \`Mb d' MM 8M'  \`Mb MM'    \` MM    6M'  \`Mb MM69 \" 
     \`Mb MM    \`'     ,oMM  MM'   MM        M  YM.P  MM     ,oMM YM.      MM    MM    MM MM'    
      MM MM       ,6MM9'MM  MM    MM        M  \`Mb'  MM ,6MM9'MM  YMMMMb  MM    MMMMMMMM MM     
      MM MM       MM'   MM  MM    MM        M   YP   MM MM'   MM      \`Mb MM    MM       MM     
L    ,M9 YM.   d9 MM.  ,MM  MM    MM        M   \`'   MM MM.  ,MM L    ,MM YM.  ,YM    d9 MM     
MYMMMM9   YMMMM9  \`YMMM9'Yb_MM_  _MM_      _M_      _MM_\`YMMM9'YbMYMMMM9   YMMM9 YMMMM9 _MM_    
                                                                                                
                                                                                                
                                                                                                
"

# Function to check if a command executed successfully
check_command_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed."
        exit 1
    fi
}

# Function to check if a tool is installed
check_tool_installed() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed. Please install it first."
        exit 1
    fi
}

# Check if required tools are installed
check_tool_installed "nmap"
check_tool_installed "gobuster"

# Check if target parameter is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <target>"
    exit 1
fi

# Check if the script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script requires root privileges to run."
    exit 1
fi

# Create results directory if it doesn't exist
results_dir="results"
mkdir -p "$results_dir"

# Store the target parameter
target="$1"

# Perform Nmap quick scan and save results to a file
echo "Running Nmap quick scan for target: $target"
nmap -T4 -F "$target" > "$results_dir/quick_scan_result.txt" 2>&1
check_command_success "Nmap quick scan"
echo "Quick scan complete. Results saved in $results_dir/quick_scan_result.txt."

# Run advanced Nmap scan in the background and notify when it completes
echo "Running advanced Nmap scan for target: $target"
nmap -p- -sV -O -T4 -A --script=default,exploit,vuln "$target" > "$results_dir/advanced_scan_result.txt" &
pid_nmap=$!

# Run Gobuster directory scan in the background if port 80 is open and notify when it completes
if grep -q "80/tcp open" "$results_dir/quick_scan_result.txt"; then
    echo "Running Gobuster directory scan on port 80 for target: $target"
    gobuster dir -u "http://$target:80" -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt > "$results_dir/gobuster_result.txt" &
    pid_gobuster=$!
fi

# Wait for the advanced Nmap scan to complete and send notification
wait $pid_nmap && notify-send "Nmap Scan Completed" "Advanced Nmap scan for $target has completed."

# Wait for the Gobuster directory scan to complete and send notification if applicable
if [ -n "$pid_gobuster" ]; then
    wait "$pid_gobuster" && notify-send "Gobuster Scan Completed" "Gobuster directory scan for $target has completed."
fi

echo "Nmap and Gobuster scans have completed. Results are saved in the $results_dir directory."
