# DAS Data Transfer

This repository contains the code for the DAS data transfer system. The system is designed to transfer data from the DAS to the computing cluster autonomously on the schedule. It also includes the notification system (based on Telegram) to notify the user about the status of the transfer.

## Getting Started

### Pre-requisites
This project is fully written in shell script with `expect` (for time-based handlers) and `oathtool` (for OTP authentication), so you need to have these installed on your system. You can install them using the following commands:

*For Debian-based systems:*
```bash
sudo apt-get install expect oathtool
```

### Installation

Clone the repository:
```bash
git clone https://github.com/Antcating/DAS-Data-Transfer.git
cd DAS-Data-Transfer
```

Add execution permission to the script:
```bash
chmod +x to_cluster_wrapper.sh
```

### Configuration

There are configurations that you need to set before running the script. You can find the configurations in the `to_cluster.sh` file. Here are the configurations that you need to set:

- `local_path`: The path to the local directory where the data is stored.
- `remote_path`: The path to the remote directory where the data will be stored.
- `remote_host`: The hostname of the remote server.
- `bridge_host`: The hostname of the bridge server.
- `remote_user`: The name of the user on the remote server.

Also you need to create files with the following names and fill them with the required information:
- `.otp/hurcs-pass`: The password of the user on the remote server.
- `.otp/hurcs-secret`: The secret key for the OTP authentication.
- `.logger/token`: The token of the Telegram bot.
- `.logger/chat_id`: The chat ID of the channel.

## Running the script

You can run the script using the following command:
```bash
./to_cluster_wrapper.sh
```

## Schedule the script

The repository includes a `systemd` service and timer to schedule the script. You will need to modify the `systemd/transfer-data-cluster.service` file to match your configurations (absolute path to the script).

You can enable the service using the following command:
```bash
cp systemd/* ~/.config/systemd/user/
systemctl --user enable transfer-data-cluster.timer
systemctl --user start transfer-data-cluster.timer
```
