#!/bin/bash

BASE=`pwd`
LUAJIT="LuaJIT-2.1.0-beta3"
LFS="luafilesystem-v_1_6_3"
RAPIDJSON="lua-rapidjson-0.5.1"
RDKAFKA="librdkafka-0.9.5"

function check_binary(){
    if [ ! -f "$1" ]; then  
        return 0
    else
        return 1
    fi
}

function build_luajit(){
    cd $BASE
    echo "    1. LuaJIT-2.1.0-beta3"
    tar zxf $LUAJIT.tar.gz
    cd $BASE/$LUAJIT
    make > .make.log 2>&1 

    #check binary, copy target 
    if [ -f "$BASE/$LUAJIT/src/luajit" ]; then
        cp $BASE/$LUAJIT/src/luajit $BASE/../libs/
        cp $BASE/$LUAJIT/src/libluajit.so $BASE/../libs/
    else
        echo "1. build failed, cat .make.log"
    fi
    echo "    1. done"
}

function build_lfs(){
    cd $BASE
    echo "    2. luafilesystem-v_1_6_3"
    tar zxf $LFS.tar.gz
    cd $BASE/$LFS
    sed -i "s/PREFIX=\/usr\/local/PREFIX=..\/$LUAJIT\/src/g" config
    sed -i "s/LUA_INC= \$(PREFIX)\/include/LUA_INC=..\/$LUAJIT\/src/g" config
    make > .make.txt 2>&1

    #check binary, copy target
    if [ -f "$BASE/$LFS/src/lfs.so" ]; then
        cp $BASE/$LFS/src/lfs.so $BASE/../libs/
    else
        echo "2. build failed, cat .make.log"
    fi

    echo "    2. done"
}

function build_librdkafk() {
    cd $BASE
    echo "    3. librdkafka-v0.9.5"
    tar zxf $RDKAFKA.tar.gz
    cd $BASE/$RDKAFKA
    ./configure > build_output_all.txt 2>&1
    make > .make.txt 2>&1

    #check binary, copy target
    if [ -f "$BASE/$RDKAFKA/src/librdkafka.so.1" ]; then
         cp $BASE/$RDKAFKA/src/librdkafka.so.1 $BASE/../libs/
    else
         echo "3. build failed, cat .make.log"
    fi

    echo "    3 done"
}

function build_rapidjson(){
    cd $BASE
    echo "    4. lua-rapidjson-v0.5.1"
    tar zxf $RAPIDJSON.tar.gz
    cd $BASE/$RAPIDJSON
    cmake -DLUA_INCLUDE_DIR=../$LUAJIT/src  CMakeLists.txt > build_output_all.txt 2>&1
    make > .make.txt 2>&1
 
    #check binary, copy target
    if [ -f "$BASE/$RAPIDJSON/rapidjson.so" ]; then
        cp $BASE/$RAPIDJSON/rapidjson.so $BASE/../libs/
    else
        echo "3. build failed, cat .make.log"
    fi
    echo "    4 done"
}


function gen_libs_lua() {
    PATH_STR="package.cpath='$BASE/../libs/?.so;'"
    echo $PATH_STR > $BASE/../libs.lua
    mkdir $BASE/../libs
}

function main()  {
    echo "build dependences....."
    gen_libs_lua
    build_luajit
    build_lfs
    build_librdkafk
    build_rapidjson
}

function clean(){
    cd $BASE
    rm -fr $LUAJIT
    rm -fr $LFS
    rm -fr $RAPIDJSON
    rm -fr $RDKAFKA
}

case "$1" in
  clean)
     clean
     exit 0
     ;;
  run)
     main
     exit 0
     ;;
   *)
     echo "Usage: $0 {run|clean}"
     exit 1
esac
