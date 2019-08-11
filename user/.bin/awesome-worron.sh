#!/bin/sh

rm ~/.config/awesome
ln -s ~/.config/awesome.worron ~/.config/awesome
pkill -HUP awesome