#!/bin/bash

# Detailed Installation Guide for OPI on Ubuntu 22.04

# Function to install and run bitcoind
install_bitcoind() {
    echo "Installing and running bitcoind..."
    sudo apt update
    sudo apt install snapd
    snap install bitcoin-core

    # If you want to use a mounted media as chain folder
    snap connect bitcoin-core:removable-media

    # Create a folder for bitcoin chain
    mkdir /mnt/HC_Volume/bitcoin_chain

    # Run bitcoind using the new folder
    bitcoin-core.daemon -txindex=1 -datadir="/mnt/HC_Volume/bitcoin_chain" -rest
}

# Function to install PostgreSQL
install_postgresql() {
    echo "Installing PostgreSQL..."
    sudo apt update
    sudo apt install postgresql postgresql-contrib
    sudo systemctl start postgresql.service

    # Optional: Mark postgres on hold
    sudo apt-mark hold postgresql postgresql-14 postgresql-client-14 postgresql-client-common postgresql-common postgresql-contrib

    # Set a password for postgresql user
    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '********';"

    # Optional: Configure pg_hba.conf for remote connection
    sudo nano /etc/postgresql/14/main/pg_hba.conf
    # Add: hostssl all             all             <ip_address_of_your_pc>/32       scram-sha-256

    # Reload the new configuration
    sudo -u postgres psql -c "SELECT pg_reload_conf();"

    # Optional: Configure postgresql.conf
    sudo nano /etc/postgresql/14/main/postgresql.conf
    # Add: listen_addresses = '*'
    # Add: max_connections = 2000

    sudo systemctl restart postgresql
}

# Function to install NodeJS
install_nodejs() {
    echo "Installing NodeJS..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

    NODE_MAJOR=20
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list

    sudo apt-get update
    sudo apt-get install nodejs -y
}

# Function to install Cargo & Rust
install_cargo_rust() {
    echo "Installing Cargo & Rust..."
    curl https://sh.rustup.rs -sSf | sh
    source "$HOME/.cargo/env"

    # Update cargo & rust
    rustup update stable
}

# Function to clone the repository
clone_repository() {
    echo "Cloning the repository..."
    git clone https://github.com/bestinslot-xyz/OPI.git
    cd OPI
}

# Function to install node modules
install_node_modules() {
    echo "Installing node modules..."
    cd modules/main_index && npm install
    cd ../brc20_api && npm install
    cd ../bitmap_api && npm install
    cd ../pow20_api && npm install
    cd ../sns_api && npm install
    cd ../..
}

# Function to install python libraries
install_python_libraries() {
    echo "Installing python libraries..."
    python3 -m pip install python-dotenv psycopg2-binary json5 stdiomask requests
}

# Function to build ord
build_ord() {
    echo "Building ord..."
    sudo apt install build-essential
    cd ord && cargo build --release
    cd ..
}

# Function to initialize .env configuration and databases
initialize_env_databases() {
    echo "Initializing .env configuration and databases..."
    python3 reset_init.py
}

# Function to restore from an online backup for faster initial sync
restore_from_backup() {
    echo "Restoring from online backup for faster initial sync..."
    sudo apt update
    sudo apt install postgresql-client-common postgresql-client-14 pbzip2
    python3 -m pip install boto3 tqdm
    cd modules && python3 restore.py
    cd ..
}

# Function to run all components
run_all() {
    echo "Running all components..."

    # Main Meta-Protocol Indexer
    echo "Running Main Meta-Protocol Indexer..."
    cd modules/main_index && node index.js &
    
    # BRC-20 Indexer
    echo "Running BRC-20 Indexer..."
    cd ../brc20_index && python3 brc20_index.py &

    # Bitmap Indexer
    echo "Running Bitmap Indexer..."
    cd ../bitmap_index && python3 bitmap_index.py &

    # SNS Indexer
    echo "Running SNS Indexer..."
    cd ../sns_index && python3 sns_index.py &

    # POW20 Indexer
    echo "Running POW20 Indexer..."
    cd ../pow20_index && python3 pow20_index.py &

    # BRC-20 API
    echo "Running BRC-20 API..."
    cd ../../brc20_api && node api.js &

    # Bitmap API
    echo "Running Bitmap API..."
    cd ../bitmap_api && node api.js &

    # SNS API
    echo "Running SNS API..."
    cd ../sns_api && node api.js &

    # POW20 API
    echo "Running POW20 API..."
    cd ../pow20_api && node api.js &
}

# Main script execution
install_bitcoind
install_postgresql
install_nodejs
install_cargo_rust
clone_repository
install_node_modules
install_python_libraries
build_ord
initialize_env_databases
restore_from_backup
run_all

echo "All components installed and running."
