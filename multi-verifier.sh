#!/bin/bash

# Display a message in cyan color
echo -e "\033[36m🌟 Showing ANIANI!!! 🌟\033[0m"

# Display the message and fetch the logo from the provided URL
echo -e "\033[32m💻 Fetching the logo...\033[0m"
wget -qO- https://raw.githubusercontent.com/Chupii37/Chupii-Node/refs/heads/main/Logo.sh | bash
if [ $? -ne 0 ]; then
    echo -e "\033[31m❌ Error: Failed to fetch or display the logo. ❌\033[0m"
    exit 1
fi

# Ask the user how many reward addresses they want to use
echo -e "\033[33m🔢 How many reward addresses do you want to use?\033[0m"
read -r NUM_ADDRESSES

# Ensure the number of addresses is valid (positive number)
if [[ ! "$NUM_ADDRESSES" =~ ^[0-9]+$ ]] || [ "$NUM_ADDRESSES" -le 0 ]; then
  echo -e "\033[31m❌ Error: The number of addresses must be a positive number. ❌\033[0m"
  exit 1
fi

# Initialize an array to store the reward addresses
declare -a HALIM_ADDRESSES

# Ask the user to input the reward addresses
for ((i = 1; i <= NUM_ADDRESSES; i++)); do
  echo -e "\033[35m🔑 Please enter reward address #$i (example: 0x123...):\033[0m"
  read -r HALIM

  # Ensure the address is not empty
  if [[ -z "$HALIM" ]]; then
    echo -e "\033[31m❌ Error: Reward address cannot be empty. ❌\033[0m"
    exit 1
  fi

  # Store the address in the array
  HALIM_ADDRESSES+=("$HALIM")
done

# Download and run the setup script from GitHub for each address
for ((i = 0; i < NUM_ADDRESSES; i++)); do
  HALIM=${HALIM_ADDRESSES[$i]}
  echo -e "\033[34m🚀 Setting up with reward address: $HALIM\033[0m"

  # Download and run the setup script for the current address
  curl -L https://github.com/cysic-labs/phase2_libs/releases/download/v1.0.0/setup_linux.sh > ~/setup_linux.sh
  bash ~/setup_linux.sh "$HALIM"

  # Wait for the setup process to complete for this address
  wait

  # Create a systemd service configuration file for the cysic service with a unique name
  sudo tee /etc/systemd/system/cysic_halim${i+1}.service > /dev/null << EOF
[Unit]
Description=Cysic Verifier Node for $HALIM
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

  # Reload systemd to recognize the cysic service
  sudo systemctl daemon-reload

  # Enable the cysic service to start automatically on boot
  sudo systemctl enable cysic_halim${i+1}.service

  # Start the cysic service
  sudo systemctl start cysic_halim${i+1}.service
done

# After all addresses are set up, display the commands to view the logs for each address
echo -e "\033[33m📝 Here are the commands to view the cysic logs for each reward address...\033[0m"

# Loop to display the journalctl commands for each address
for ((i = 0; i < NUM_ADDRESSES; i++)); do
  HALIM=${HALIM_ADDRESSES[$i]}
  # Display the journalctl command for each address in the format HALIM1, HALIM2, etc.
  echo -e "\n\n\033[36m========================================\033[0m"
  echo -e "\033[32m📜 Command to view cysic log for address HALIM$(($i+1)):\033[0m"
  echo -e "\033[35msudo journalctl -u cysic_halim$(($i+1)).service -f --no-hostname -o cat\033[0m"
  echo -e "\033[36m========================================\033[0m\n\n"
done

# Final message
echo -e "\033[32m🎉 Setup complete! You can now view the logs using the commands above. 🎉\033[0m"
