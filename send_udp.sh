while true; do
	echo "here we go"
	echo -n "hello" | nc -4u -vv test-lb-tf-5c32396545328bf5.elb.eu-west-2.amazonaws.com 1503 >> /tmp/udp_log
	#echo "hi" | socat -t 0 - UDP:test-lb-tf-5c32396545328bf5.elb.eu-west-2.amazonaws.com:1503 > results

done
