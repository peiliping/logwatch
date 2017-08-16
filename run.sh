#!/bin/bash

LD_LIBRARY_PATH=`pwd`/libs

nohup ./libs/luajit agent.lua > agent.log 2>&1 &
