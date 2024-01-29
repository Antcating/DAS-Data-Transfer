while [ $? -ne 0 ]; do
	echo "Restarting..."
	sleep 30
    	/usr/bin/expect {ABSOLUTE_PATH_TO_WORKING_DIR}/to_cluster.sh
	curl -s -X POST https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage -d chat_id={TELEGRAM_CHAT_ID} -d text="Transfer has been restated due to error"
done
echo "Transfer finished successfully"
curl -s -X POST https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage -d chat_id={TELEGRAM_CHAT_ID} -d text="Specified transder has been finished successfully"