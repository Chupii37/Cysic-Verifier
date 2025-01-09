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
declare -a HALIM_ADDRESSES

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
  HALIM_ADDRESSES+=("$REWARD_ADDRESS")

  # Download and run the setup script for the current address
  curl -L https://github.com/cysic-labs/phase2_libs/releases/download/v1.0.0/setup_linux.sh > ~/setup_linux.sh
  bash ~/setup_linux.sh "$REWARD_ADDRESS"
  
  # Create the systemd service for the current address
  sudo tee /etc/systemd/system/cysic_halim$i.service > /dev/null << EOF
[Unit]
Description=Cysic Verifier Node for HALIM$i
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
  sudo systemctl enable cysic_halim$i.service

  # Start the service
  sudo systemctl start cysic_halim$i.service

  # Wait for the setup to complete before moving to the next address
  echo -e "\033[32m🔄 Setup for address $REWARD_ADDRESS completed.\033[0m"
done

# After setting up all services:
echo -e "\033[33m📝 Here is the command to view the cysic log for each reward address...\033[0m"

# Loop through the addresses to display the commands to view logs
for ((i = 1; i <= NUM_ADDRESSES; i++)); do
  echo -e "\033[36m========================================\033[0m"
  echo -e "\033[32m📜 Command to view the cysic log for address HALIM$i:\033[0m"
  echo -e "\033[35msudo journalctl -u cysic_halim$i.service -f --no-hostname -o cat\033[0m"
  echo -e "\033[36m========================================\033[0m\n"
done

echo -e "\033[32m🎉 Setup complete! You can now view the logs using the above command. 🎉\033[0m"
