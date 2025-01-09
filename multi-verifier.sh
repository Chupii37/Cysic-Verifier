#!/bin/bash

# Set the path where the service will be located
SERVICE_FILE="/etc/systemd/system/multi-wallet-setup.service"
SCRIPT_FILE="/root/multi-verifier.sh"  
USER="root"  
GROUP="root" 

# Create the systemd service file directly without creating an additional bash script
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

# Display a message in cyan color
echo -e "\033[36mShowing ANIANI!!!\033[0m"

# Display the message and fetch the logo from the provided URL
echo -e "\033[32mMenampilkan logo...\033[0m"
wget -qO- https://raw.githubusercontent.com/Chupii37/Chupii-Node/refs/heads/main/Logo.sh | bash

# Prompt user for the number of wallets
echo -n "Enter the number of wallets to set up: "
read WALLET_AMOUNT

# Check if the user entered a valid number
if [[ -z "$WALLET_AMOUNT" || ! "$WALLET_AMOUNT" =~ ^[0-9]+$ || "$WALLET_AMOUNT" -le 0 ]]; then
    echo "Invalid number of wallets. Please enter a positive integer."
    exit 1
fi
echo "You selected to use $WALLET_AMOUNT wallet(s)."

# Prompt user for wallet addresses (comma-separated)
echo "Please enter the wallet addresses separated by commas (e.g., wallet1, wallet2, wallet3):"
read WALLET_ADDRESSES

# Check if wallet addresses are provided
if [[ -z "$WALLET_ADDRESSES" ]]; then
    echo "Error: WALLET_ADDRESSES not provided. Please enter wallet addresses."
    exit 1
fi

# Convert the comma-separated wallet addresses into an array
IFS=',' read -r -a wallet_addresses <<< "$WALLET_ADDRESSES"

# Check if the number of wallet addresses matches the wallet amount
if [[ ${#wallet_addresses[@]} -ne "$WALLET_AMOUNT" ]]; then
    echo "Error: The number of wallet addresses doesn't match the number of wallets. Please provide exactly $WALLET_AMOUNT addresses."
    exit 1
fi

# Loop through each wallet address and run the setup script
for (( i=0; i<${#wallet_addresses[@]}; i++ )); do
    wallet_address="${wallet_addresses[$i]}"
    echo "Running setup for wallet address: $wallet_address"

    # Download and execute the setup script for each wallet
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
