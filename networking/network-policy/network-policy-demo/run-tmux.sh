#!/usr/bin/env bash

PID=$$

set -x
if [ "$1" == "" ] ; then
  echo "Please run $0 <domain>"
  exit 1;
fi

SERVER=$1

if [ -z $TMUX ] ; then
  echo "Start new tmux session"
  tmux new-session -d -s demo-$PID "watch curl -s -k https://homer-simpson.${SERVER}/demo"
fi
tmux split-window -d -t 0 -v  "watch curl -s -k https://marge-simpson.${SERVER}/demo"
tmux split-window -d -t 0 -h  "watch curl -s -k https://selma-bouvier.${SERVER}/demo"
tmux split-window -d -t 2 -h  "watch curl -s -k https://patty-bouvier.${SERVER}/demo"
if [ -z $TMUX ] ; then
  echo "Attach to session"
  tmux attach-session -t demo-$PID
else
  watch curl -s -k http://homer-simpson.${SERVER}/demo
fi
