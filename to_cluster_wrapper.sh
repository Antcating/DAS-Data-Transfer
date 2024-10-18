pushd $(dirname $0) > /dev/null

TELEGRAM_BOT_TOKEN=$(cat .logger/token)
TELEGRAM_CHAT_ID=$(cat .logger/chat_id)

attempt=1
max_attempts=3
/usr/bin/expect ./to_cluster.sh
while [ $? -ne 0 ] && [ $attempt -lt $max_attempts ]; do
	# curl -s -X POST https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage -d chat_id=$TELEGRAM_CHAT_ID -d text="Transfer has been restarted due to error (Attempt $attempt)"
	echo "Restarting... (Attempt $attempt)"
	sleep 30
	attempt=$((attempt + 1))
	/usr/bin/expect ./to_cluster.sh
done

if [ $attempt -lt $max_attempts ]; then
	echo "Transfer finished successfully"
	curl -s -X POST https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage -d chat_id=$TELEGRAM_CHAT_ID -d text="Transfer finished successfully after $attempt attempts"
else
	error_log=$(tail -n 5 rsync.log)
	echo "Transfer failed after $attempt attempts"
	curl -s -X POST https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage -d chat_id=$TELEGRAM_CHAT_ID -d text="Transfer failed after $attempt attempts:%0A%0ALog:%0A$error_log"
fi
