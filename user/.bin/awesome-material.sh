#!/bin/sh

rm ~/.config/awesome
ln -s ~/.config/awesome.material ~/.config/awesome
pkill -HUP awesome