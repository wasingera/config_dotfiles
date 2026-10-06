#!/bin/bash

vol=
if [ ! $vol ]; then
    vol=50
fi
pamixer --set-volume $vol
