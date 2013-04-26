package com.weiplus.client;

import haxe.Json;
import nme.events.Event;
import com.roxstudio.haxe.net.RoxURLLoader;
import haxe.BaseCode;

class HpApi {

    public static inline var BASE_URL = "http://www.appmagics.com/api";

    public static var instance(get_instance, null): HpApi;

    public var accessToken: String;
    public var uid: String;
    public var refreshToken: String;

    private function new(json: Dynamic) {
        update(json);
    }

    private static function get_instance() : HpApi {
        if (instance == null) {
#if android
            instance = new HpApi(Json.parse(HpManager.getTokenAsJson()));
#else
            instance = new HpApi({ accessToken: "", uid: "", refreshToken: "" });
#end
        }
#if android
        if (instance.accessToken == null || instance.accessToken == "") {
            instance.update(Json.parse(HpManager.getTokenAsJson()));
        }
#end
        return instance;
    }

    public function update(json: Dynamic) {
        this.accessToken = json.accessToken;
        this.uid = json.uid;
        this.refreshToken = json.refreshToken;
    }

    public function makeUrl(uri: String) {
        return BASE_URL + uri + ".json";
    }

    public function encodeParam(params: Dynamic) {
        var buf = new StringBuf();
        if (accessToken != null && accessToken.length > 0) {
            buf.add("accessToken=");
            buf.add(accessToken);
            buf.add("&refreshToken=");
            buf.add(refreshToken);
            buf.add("&format=json");
        }
        for (k in Reflect.fields(params)) {
            var val = Reflect.field(params, k);
            switch (true) {
                case Std.is(val, Int), Std.is(val, Float): addBuf(buf, k, "" + val);
                case Std.is(val, String): addBuf(buf, k, StringTools.urlEncode(cast val));
                case val == null: addBuf(buf, k, "");
            }
        }
        return buf.toString();
    }

    private static inline function addBuf(buf: StringBuf, key: String, val: String) {
        buf.add("&");
        buf.add(key);
        buf.add("=");
        buf.add(val);
    }

    public function get(uri: String, params: Dynamic, onComplete: Int -> Dynamic -> Void) {
        var url = makeUrl(uri);
        var qry = encodeParam(params);
        trace("HpApi.get: url=" + (url + "?" + qry));
        var ldr = new RoxURLLoader(url + "?" + qry, RoxURLLoader.TEXT);
        ldr.addEventListener(Event.COMPLETE, function(e: Dynamic) {
            var status: Int = e.target.status;
            var code: Int = -1, data: Dynamic = null;
            if (status == RoxURLLoader.OK) {
                var jsonStr: String = e.target.data;
                try {
                    var json = Json.parse(jsonStr);
                    code = json.code;
                    data = json;
                } catch (e: Dynamic) {
                    code = -2;
                    data = "Invalid return data format.";
                }
            } else {
                code = -1; // network error
                data = "Network error.";
            }
            var datastr: String = "" + data;
            trace("get.onComplete: code=" + code + ",data=" + (datastr.length > 80 ? datastr.substr(0, 80) + "..." : datastr));
            onComplete(code, data);
        });
    }

//    private function complete()

}
