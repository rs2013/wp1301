package com.roxstudio.haxe.io;

#if cpp
import sys.FileSystem;
#end

using StringTools;

class FileUtil {

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

    public static function fullPath(path: String) {
        var isFull = false;
#if windows
        var c: Int;
        isFull = path.length > 3 && path.charAt(1) == ":"
                && ((c = path.charCodeAt(0)) >= 0x41 && c <= 0x5A || c >= 0x61 && c <= 0x7A); // A-Za-z
#else // android, linux etc.
        isFull = path.startsWith("/");
#end
        return isFull ? path : FileSystem.fullPath(path);
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


}
