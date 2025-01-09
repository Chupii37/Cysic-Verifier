#!/bin/bash

# Set the path where the service and script will be located
SERVICE_FILE="/etc/systemd/system/multi-wallet-setup.service"
SCRIPT_FILE="/root/multi-verifier.sh"  
USER="root"  
GROUP="root" 

# Function to create the systemd service file
create_systemd_service() {
    echo "Creating systemd service file..."

    cat <<EOL > $SERVICE_FILE
[Unit]
Description=Run Multiple Wallet Setup Scripts
After=network.target

[Service]
ExecStart=$SCRIPT_FILE
Restart=always
User=$USER
Group=$GROUP
WorkingDirectory=$(dirname $SCRIPT_FILE)
Environment=WALLET_AMOUNT=50
Environment=WALLET_ADDRESSES=0x1234567890abcdef1234567890abcdef12345678,0xabcdefabcdefabcdefabcdefabcdefabcdefabcdef
StandardOutput=journal
StandardError=journal
Environment=HOME=/root

[Install]
WantedBy=multi-user.target
EOL

    # Reload systemd, enable and start the service
    echo "Reloading systemd, enabling and starting the service..."
    sudo systemctl daemon-reload
    sudo systemctl enable multi-wallet-setup.service
    sudo systemctl start multi-wallet-setup.service

    echo "Systemd service created and started successfully."
}

# Function to create the actual bash script that will be run by systemd
create_bash_script() {
    echo "Creating the bash script..."

    cat <<'EOL' > $SCRIPT_FILE
#!/bin/bash

# Make the script executable
chmod +x ~/setup_linux.sh

# Display a message in cyan color
echo -e "\033[36mShowing ANIANI!!!\033[0m"

# Display the message and fetch the logo from the provided URL
echo -e "\033[32mMenampilkan logo...\033[0m"
wget -qO- https://raw.githubusercontent.com/Chupii37/Chupii-Node/refs/heads/main/Logo.sh | bash

# Check if WALLET_AMOUNT is passed as an environment variable
if [[ -z "$WALLET_AMOUNT" ]]; then
    echo "Error: WALLET_AMOUNT not set. Please set the wallet amount in the service configuration."
    exit 1
fi
echo "You selected to use $WALLET_AMOUNT wallet(s)."

# Check if WALLET_ADDRESSES are passed as an environment variable
if [[ -z "$WALLET_ADDRESSES" ]]; then
    echo "Error: WALLET_ADDRESSES not set. Please provide wallet addresses in the service configuration."
    exit 1
fi

# Convert the comma-separated wallet addresses into an array
IFS=',' read -r -a wallet_addresses <<< "$WALLET_ADDRESSES"

# Loop through each wallet address and run the setup script
for (( i=0; i<${#wallet_addresses[@]}; i++ )); do
    wallet_address="${wallet_addresses[$i]}"
    echo "Running setup for wallet address: $wallet_address"
    
    # Download and run the setup script
    /usr/bin/curl -L https://github.com/cysic-labs/phase2_libs/releases/download/v1.0.0/setup_linux.sh > ~/setup_linux.sh
    /bin/bash ~/setup_linux.sh "$wallet_address"
    
    # Check if the setup ran successfully
    if [[ $? -ne 0 ]]; then
        echo "Error setting up wallet $wallet_address. Exiting."
        exit 1
    fi

    # Optional: Wait for the previous process to complete before continuing to the next
    echo "Wallet $((i + 1)) setup completed."
done

# Now, run the start script after all wallets have been processed
cd ~/cysic-verifier/ && /bin/bash start.sh

# After completing the tasks, display the logs using journalctl
echo "The setup is complete. Checking logs..."
sudo journalctl -u multi-wallet-setup.service -f --no-hostname -o cat
EOL

    # Make the bash script executable
    chmod +x $SCRIPT_FILE

    echo "Bash script created successfully."
}

# Step 1: Create the bash script
create_bash_script

# Step 2: Create the systemd service and start it
create_systemd_service

# Check if systemd is running and output the status
echo "Checking systemd service status..."
sudo systemctl status multi-wallet-setup.service
