package com.weiplus.client;

#if android
import nme.JNI;

class AndroidHelper {

    private static var _startActivity: Dynamic;
    private static var _startImageCapture: Dynamic;
    private static var _getResult: Dynamic;

    public function new() {
    }

    /*
     * public static void startActivity(String activityClassName, int requestCode, String[] pairs)
     * className like: "com.company.app.MyActivity"
     * pairs: activity param in key-value pairs, e.g.: [ "name", "Peter", "age", "32" ]
     */
    public static function startActivity(className: String, requestCode: Int, ?pairs: Array<String>) {
        if (_startActivity == null) {
            _startActivity = JNI.createStaticMethod("com/weiplus/client/HaxeHelper",
            "startActivity",
            "(Ljava/lang/String;I[Ljava/lang/String;)V");
        }
        nme.Lib.postUICallback(function() { _startActivity(className, requestCode, pairs); });
    }

    /*
     * public static void startImageCapture(int requestCode, String snapFilePath)
     */
    public static function startImageCapture(requestCode: Int, snapFilePath: String) {
        if (_startImageCapture == null) {
            _startImageCapture = JNI.createStaticMethod("com/weiplus/client/HaxeHelper",
            "startImageCapture",
            "(ILjava/lang/String;)V");
        }
        nme.Lib.postUICallback(function() { _startImageCapture(requestCode, snapFilePath); });
    }

    /*
     * public static String[] getResult(int requestCode)
     */
    public static function getResult(requestCode: Int) : Array<String> {
        if (_getResult == null) {
            _getResult = JNI.createStaticMethod("com/weiplus/client/HaxeHelper",
            "getResult",
            "(I)[Ljava/lang/String;");
        }
        return _getResult(requestCode);
    }

    public static function toJavaMap(data: Dynamic) : Dynamic {
        trace("tojavamap start");
        //var Class_forName = JNI.createStaticMethod("java/lang/Class", "forName", "(Ljava/lang/String;)Ljava/lang/Class;");
        //var Class_newInstance = JNI.createMemberMethod("java/lang/Class", "newInstance", "()Ljava/lang/Object;");
        var Integer_valueOf = JNI.createStaticMethod("java/lang/Integer", "valueOf", "(I)Ljava/lang/Integer;");
        var Map_new = JNI.createStaticMethod("java/util/HashMap", "<init>", "()V") ;
        var Map_put = JNI.createMemberMethod("java/util/Map", "put", "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;") ;
        var Map_size = JNI.createMemberMethod("java/util/Map", "size", "()I") ;
        var Object_toString = JNI.createMemberMethod("java/lang/Object", "toString", "()Ljava/lang/String;");
        trace("tojavamap classok");
        //var clz = Class_forName("java.util.HashMap");
        //trace("tojavamap forname ok");
        var map = Map_new();
        trace("tojavamap newinst ok: size=" + Map_size(map));
        for (k in Reflect.fields(data)) {
            var v = Reflect.field(data, k); // TODO: handle properties
            trace("k=" + k + ",v=" + v);
            if (Std.is(v, Int)) {
                var integer = Integer_valueOf(cast(v, Int));
                Map_put(map, untyped k, integer);
            } else if (Std.is(v, String)) {
                Map_put(map, untyped k, cast(v, String));
            } else if (Std.is(v, nme.utils.ByteArray)) {
                Map_put(map, k, v);
            } else {
                throw "toJavaMap: unsupported type";
            }
        }
        trace(">>>>>>>tostring=" + Object_toString(map));
        return map;
    }

}
#end