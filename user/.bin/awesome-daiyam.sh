#!/bin/sh

rm ~/.config/awesome
ln -s ~/.config/awesome.daiyam ~/.config/awesome
pkill -HUP awesome