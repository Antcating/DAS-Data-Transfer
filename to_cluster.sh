
#!/usr/bin/expect

set timeout 180000
set local_port 13579
set remote_host {hurcs-login-server}
set remote_port 22
set bridge_host {hurcs-bridge-host}
set server {hurcs-login-server-name}
set username {hurcs-username}
set password [exec cat {ABSOLUTE_PATH_TO_WORKING_DIR}/.otp/hurcs-pass]
set otp_secret [exec cat {ABSOLUTE_PATH_TO_WORKING_DIR}/.otp/hurcs-secret]
set last_job_id [exec cat {ABSOLUTE_PATH_TO_WORKING_DIR}/last_job.txt]

set local_path "{ABSOLUTE_PATH_TO_CONCATENATED_DATA_DIR}"
# set local_path "{ABSOLUTE_PATH_TO_WORKING_DIR}/test-dir"
# read OTP password using oathtool from the file
set otp [exec oathtool --totp -b $otp_secret]

# set to_sync [exec find $local_path -type f -mtime -60 -mtime +20 -printf "%P\n"]
set to_sync [exec find $local_path -type d -mtime -15 -mtime +5  -printf "%P\n"]
#set to_sync [exec find $local_path -type f -printf "%P\n"]
puts "Files to sync: $to_sync"
# Write the list of relative paths to the file to_sync.txt
exec printf "%s" "$to_sync" > to_sync.txt

# print $local_path
puts "Local path: $local_path"
set remote_path {ABSOLUTE_PATH_TO_REMOTE_DIR}

# read OTP password using oathtool from the file
set otp [exec oathtool --totp -b $otp_secret]

# Set hostname from the server to the variable
set remote_PID [spawn ssh -J $username@$bridge_host $username@$remote_host]
expect "(OTP) Password:"
send "$otp\r"
expect "(IDng) Password:"
send "$password\r"
sleep 3
expect "Last login"
send "ls -l\r"

send "ls -l $remote_path\r"
send "echo 'test' >> test.transfer\r"
send "squeue -u $username\r"
send "scancel $last_job_id\r"
send "salloc --time=2-00:00:00 --mem=4G & \r"
# Wait for row starting with sallos: Nodes and save the hostname
expect -re "salloc: job (.*) queued and waiting for resources"
set job_id $expect_out(1,string)

puts "Job ID: $job_id"
exec echo $job_id > last_job.txt

expect -re "salloc: Nodes (.*)"
set remote_hostname $expect_out(1,string)
# Cut last character from the hostname
set remote_hostname [string range $remote_hostname 0 end-20]


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

spawn rsync -arvz --info=progress2 -e "ssh -oStrictHostKeyChecking=no -p $local_port" --include=to_sync.txt $local_path $username@localhost:$remote_path --log-file=rsync.log
expect "(IDng) Password:"
send "$password\r"
expect eof
