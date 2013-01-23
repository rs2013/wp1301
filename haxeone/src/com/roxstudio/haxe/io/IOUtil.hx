package com.roxstudio.haxe.io;

import haxe.io.Bytes;
import nme.utils.ByteArray;

class IOUtil {

    private function new() {
    }

    public static inline function rox_toByteArray(bytes: Bytes) {
        return #if flash bytes.getData() #else ByteArray.fromBytes(bytes) #end;
    }

    public static inline function rox_toBytes(byteArray: ByteArray) {
        return #if flash Bytes.ofData(byteArray) #else byteArray #end;
    }

}
