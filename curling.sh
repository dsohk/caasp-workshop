#! /bin/bash

NODE_IP=192.168.0.22
PORT=31514

while true; do curl http://$NODE_IP:$PORT/greeting; echo ""; sleep 1; done

