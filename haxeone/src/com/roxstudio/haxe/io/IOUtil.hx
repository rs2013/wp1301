package com.roxstudio.haxe.io;

#if cpp
import sys.FileSystem;
#end

import nme.utils.ByteArray;
import haxe.io.Bytes;
using StringTools;

class IOUtil {

    private function new() {
    }

#if cpp
    public static function mkdirs(path: String) {
        path = path.replace("\\", "/");
        var arr = path.split("/");
        var dir = "";
        for (i in 0...arr.length) {
            dir += arr[i] + "/";
            if (!FileSystem.exists(dir)) {
                FileSystem.createDirectory(dir);
            }
        }
    }

#end

    public static inline function rox_toByteArray(bytes: Bytes) {
        return #if flash bytes.getData() #else ByteArray.fromBytes(bytes) #end;
    }

    public static inline function rox_toBytes(byteArray: ByteArray) {
        return #if flash Bytes.ofData(byteArray) #else byteArray #end;
    }


}
