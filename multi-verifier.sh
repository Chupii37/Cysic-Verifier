#!/bin/bash

# Ask the user how many addresses they want to use
echo -e "\033[35m🔑 How many reward addresses would you like to use? (e.g., 2): \033[0m"
read -r NUM_ADDRESSES

# Check if NUM_ADDRESSES is a valid number
if [[ ! "$NUM_ADDRESSES" =~ ^[0-9]+$ ]] || [ "$NUM_ADDRESSES" -le 0 ]; then
    echo "Error: Please enter a valid number greater than 0."
    exit 1
fi

# Initialize an array to hold the reward addresses
declare -a VERIFIER_ADDRESSES

# Loop to get the reward addresses and set up the services
for ((i = 1; i <= NUM_ADDRESSES; i++)); do
  # Ask the user to input the reward address
  echo -e "\033[35m🔑 Please enter reward address #$i (example: 0x123...): \033[0m"
  read -r REWARD_ADDRESS
  
  # Ensure the address is not empty
  if [[ -z "$REWARD_ADDRESS" ]]; then
    echo "Error: Reward address cannot be empty."
    exit 1
  fi

  # Store the address in the array
  VERIFIER_ADDRESSES+=("$REWARD_ADDRESS")

  # Download the setup script
  echo -e "\033[35m🔄 Downloading setup script for address #$i...\033[0m"
  curl -L https://github.com/cysic-labs/phase2_libs/releases/download/v1.0.0/setup_linux.sh -o ~/setup_linux.sh
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to download the setup script. Please check your internet connection or the URL."
    exit 1
  fi

  # Run the setup script for the current address
  bash ~/setup_linux.sh "$REWARD_ADDRESS"
  if [[ $? -ne 0 ]]; then
    echo "Error: Setup script failed for address $REWARD_ADDRESS."
    exit 1
  fi

  # Create the systemd service for the current address
  sudo tee /etc/systemd/system/cysic_verifier$i.service > /dev/null << EOF
[Unit]
Description=Cysic Verifier Node for VERIFIER$i
After=network-online.target

[Service]
User=$USER
ExecStart=/bin/bash -c 'cd $HOME/cysic-verifier && bash start.sh' 
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  # Reload systemd to recognize the new service
  sudo systemctl daemon-reload

  # Enable the service to start automatically at boot
  sudo systemctl enable cysic_verifier$i.service

  # Start the service (but don't show the logs here)
  sudo systemctl start cysic_verifier$i.service

  # Wait for the setup to complete before moving to the next address
  echo -e "\033[32m🔄 Setup for address $REWARD_ADDRESS completed.\033[0m"
  
  # Add a 2-second delay before proceeding to the next setup
  sleep 2
done

# After setting up all services:
echo -e "\033[33m📝 Here is the command to view the cysic log for each reward address...\033[0m"

# Display the separator only once at the top
echo -e "\033[36m========================================\033[0m"

# Loop through the addresses to display the commands to view logs
for ((i = 1; i <= NUM_ADDRESSES; i++)); do
  echo -e "\033[32m📜 Command to view the cysic log for address VERIFIER$i:\033[0m"
  echo -e "\033[35msudo journalctl -u cysic_verifier$i.service -f --no-hostname -o cat\033[0m"

# Display the separator only once at the bottom
echo -e "\033[36m========================================\033[0m"
done

echo -e "\033[32m🎉 Setup complete! You can now view the logs using the above command. 🎉\033[0m"
