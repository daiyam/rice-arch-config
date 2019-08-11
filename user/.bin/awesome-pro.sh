#!/bin/sh

rm ~/.config/awesome
ln -s ~/.config/awesome.pro ~/.config/awesome
pkill -HUP awesome