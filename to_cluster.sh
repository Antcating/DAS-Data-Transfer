#!/usr/bin/expect

# -----------------------------------
# Configuration
# -----------------------------------

# Local path to the directory to sync
set local_path "{local_path}"
# Remote path to the directory to sync
set remote_path "{remote_path}"

# Local port for SSH tunnel
set local_port 13579
# Remote (cluster) host and port
set remote_host {remote_host}
set remote_port 22
set bridge_host {bridge_host}
# Bridge host is used to connect to the cluster
set server {server}
# Username for the cluster
set username {username}
# Password for the cluster
set password [exec cat ./.otp/hurcs-pass]
# OTP secret for the cluster
set otp_secret [exec cat ./.otp/hurcs-secret]
# read OTP password using oathtool from the file
set otp [exec oathtool --totp -b $otp_secret]

puts "Local path: $local_path"
puts "Remote path: $remote_path"

# Find files and directories modified in the last 15 days and not modified in the last 2 days (to avoid syncing files that are currently being written)
set to_sync [exec find $local_path -type d -mtime -15 -mtime +2  -printf "%P\n"]
## DEBUG: Find all files and directories
# set to_sync [exec find $local_path -type f -printf "%P\n"]

puts "Files to sync: $to_sync"
# Write the list of relative paths to the file to_sync.txt
exec printf "%s" "$to_sync" > to_sync.txt

# Read last job ID from the file
set last_job_id [exec cat ./last_job.txt]
# Set hostname from the server to the variable
set remote_PID [spawn ssh -o StrictHostKeyChecking=accept-new -J $username@$bridge_host $username@$remote_host]
expect "(OTP) Password:"
send "$otp\r"
expect "(IDng) Password:"
send "$password\r"
sleep 3
expect "Last login"

send "ls -l $remote_path\r"
send "echo 'test' >> test.transfer\r"
send "squeue -u yevheniif\r"
# Cancel the last job if it is still running
send "scancel $last_job_id\r"
# Request new job
send "salloc --time=0-12:00:00 & \r"
# Wait for row starting with sallos: Nodes and save the hostname
expect -re "salloc: job (.*) queued and waiting for resources"
set job_id $expect_out(1,string)

puts "Job ID: $job_id"
# Save the job ID to the file
exec echo $job_id > last_job.txt

expect -re "salloc: Nodes (.*)"
# Save the hostname to the variable
set remote_hostname $expect_out(1,string)
set remote_hostname [string range $remote_hostname 0 end-20]
set remote_hostname [string trim $remote_hostname]

puts "SSH PID: $remote_PID"
puts "Hostname: $remote_hostname"

# TOTP has timeout of 30 seconds. If login attempt has been made before timeout, cluster login will hang up and reqiure new OTP
sleep 30
# read OTP password using oathtool from the file
set otp [exec oathtool --totp -b $otp_secret]

# Create SSH tunnel to the server using the hostname and port
set tunnel_PID [spawn ssh -oStrictHostKeyChecking=no -J $username@$bridge_host -L $local_port:$remote_hostname:$remote_port $username@$remote_hostname.cs.huji.ac.il]
expect "(OTP) Password:"
send "$otp\r"
expect "(IDng) Password:"
send "$password\r"
expect "This host is part of the 'moriah' SLURM cluster"
send "Loaded\r"
expect "Loaded"

puts "Tunnel created"
# Start rsync with the list of files to sync
spawn rsync -arv --info=progress2 -e "ssh -oStrictHostKeyChecking=no -p $local_port" --exclude="*"  --files-from=to_sync.txt $local_path $username@localhost:$remote_path --log-file=rsync.log
# Wait until rsync finishes or fails
expect {
    "(IDng) Password:" {
        send "$password\r"
        exp_continue
    }
    eof {
        catch wait result
        set exit_status [lindex $result 3]
        if {$exit_status != 0} {
            set error_message [exec tail -n 10 rsync.log]
            puts "Error: rsync failed with exit status $exit_status"
            puts "Error details: $error_message"
            # Explicitly exit with the exit status of rsync
            exit $exit_status
        }
    }
}
