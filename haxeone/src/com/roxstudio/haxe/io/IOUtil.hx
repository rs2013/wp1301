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

    public static inline function fileExt(s: String, ?lowerCase: Bool = false) : String {
        var idx = s.lastIndexOf(".");
        if (lowerCase) s = s.toLowerCase();
        return idx > 0 ? s.substr(idx + 1) : "";
    }

    public static inline function fileName(s: String) : String {
        var i1 = s.lastIndexOf("/"), i2 = s.lastIndexOf(".");
        if (i2 < 0) i2 = s.length;
        return s.substr(i1 + 1, i2 - i1 - 1);
    }

    public static inline function rox_toByteArray(bytes: Bytes) {
        return #if flash bytes.getData() #else ByteArray.fromBytes(bytes) #end;
    }

    public static inline function rox_toBytes(byteArray: ByteArray) {
        return #if flash Bytes.ofData(byteArray) #else byteArray #end;
    }


}
