package com.weiplus.client;

import com.weiplus.client.model.User;
import nme.errors.Error;
import haxe.Json;
import nme.events.Event;
import com.roxstudio.haxe.net.RoxURLLoader;
#if haxe3
import haxe.crypto.BaseCode;
#else
import haxe.BaseCode;
#end

class HpApi {

//    public static inline var BASE_URL = "http://s-56378.gotocdn.com/harryphoto";
//    public static inline var BASE_URL = "http://www.appmagics.com/api";
    public static inline var BASE_URL = "http://www.appmagics.cn/api";

    private static inline var DEFAULT_UID = "113";
//    private static inline var DEFAULT_TOKEN = "c0cd303a9f13db7d79b4ec3e6cc125a9";

    public static var instance(get_instance, null): HpApi;

    public var accessToken: String;
    public var uid: String;
    public var user: User;
    public var refreshToken: String;

    private function new(json: Dynamic) {
        update(json);
    }

    private static function get_instance() : HpApi {
        if (instance == null) {
#if (android && !testin)
            if (MyUtils.isEn()) {
                instance = new HpApi({ accessToken: "45cdb6b37a59ec2273bcfd6e19dc2883", uid: "8", refreshToken: "" });
            } else {
                instance = new HpApi(Json.parse(HpManager.getTokenAsJson()));
            }
#else
//            instance = new HpApi({ accessToken: "5de6dd1b60c6e090042d9fb605136bba", uid: "7", refreshToken: "" });
//            instance = new HpApi({ accessToken: "c0cd303a9f13db7d79b4ec3e6cc125a9", uid: "113", refreshToken: "" });
//            instance = new HpApi({ accessToken: "ad589fd46c1dbea90cfb99c0010e61b4", uid: "3", refreshToken: "" });
            instance = new HpApi({ accessToken: "45cdb6b37a59ec2273bcfd6e19dc2883", uid: "8", refreshToken: "" });
#end
        }
#if (android && !testin)
        if (instance.accessToken == null || instance.accessToken == "") {
            instance.update(Json.parse(HpManager.getTokenAsJson()));
        }
#end
        return instance;
    }

//    public function useDefault() {
//        uid = DEFAULT_UID;
//        accessToken = DEFAULT_TOKEN;
//    }

    public function isDefault() {
        return uid == DEFAULT_UID;
    }

    public function update(json: Dynamic) {
        this.accessToken = json.accessToken;
        this.uid = json.uid;
        this.refreshToken = json.refreshToken;
        if (uid == null || uid == "" || uid == DEFAULT_UID) {
            this.user = null;
        } else {
            get("/users/show/" + uid, { }, function(code: Int, json: Dynamic) {
                if (code != 200) {
                    this.user = null;
                    return;
                }

                var u = json.users[0];
                this.user = new User();
                user.id = u.id;
                user.name = u.nickname;
                user.profileImage = u.avatar;
                user.createdAt = Date.fromTime(u.ctime);
                user.lastVisitAt = Date.fromTime(u.vtime);
                user.postCount = 0;
                user.friendCount = 0;
                user.followerCount = 0;
                user.friendship = u.friendship;
                var stats: Array<Dynamic> = u.stats;
                if (stats != null && stats.length > 0) {
                    for (stat in stats) {
                        var cnt = stat.count;
                        switch (stat.type) {
                            case "FRIENDS": user.friendCount = cnt;
                            case "FOLLOWERS": user.followerCount = cnt;
                            case "STATUSES": user.postCount = cnt;
                        }
                    }
                }

            });
        }
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
            if (Std.is(val, Int) || Std.is(val, Float)) {
                addBuf(buf, k, "" + val);
            } else if (Std.is(val, String)) {
                addBuf(buf, k, StringTools.urlEncode(cast val));
            } else if (val == null) {
                addBuf(buf, k, "");
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
        var ldr = new RoxURLLoader(url + "?" + qry, RoxURLLoader.TEXT, function(isOk: Bool, response: Dynamic) {
            var code: Int = -1, data: Dynamic = null;
            if (isOk) {
                var jsonStr: String = cast response;
                try {
                    var json = Json.parse(jsonStr);
                    code = json.code;
                    data = json;
                } catch (e: Dynamic) {
                    code = -2;
                    data = "Invalid response JSON data.";
                }
            } else {
                code = -1; // network error
                data = response.toString();
            }
            var datastr: String = "" + data;
//            trace("get.onComplete: code=" + code + ",data=" + (datastr.length > 80 ? datastr.substr(0, 80) + "..." : datastr));
            onComplete(code, data);
        });
        ldr.start();
    }

//    private function complete()

}
