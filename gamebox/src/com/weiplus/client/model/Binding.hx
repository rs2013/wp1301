package com.weiplus.client.model;

enum Type {
    HARRYPHOTO_WEIBO;
    SINA_WEIBO;
    TENCENT_WEIBO;
    RENREN_WEIBO;
}

class Binding {

    private function new() {
    }

    public static function name(type: Type) : String {
        return switch (type) {
            case HARRYPHOTO_WEIBO:
                "哈利波图";
            case SINA_WEIBO:
                "新浪微博";
            case TENCENT_WEIBO:
                "腾讯微博";
            case RENREN_WEIBO:
                "人人网";
        }
    }

    public static function id(type: Type) : String {
        return switch (type) {
            case HARRYPHOTO_WEIBO:
                "HARRYPHOTO_WEIBO";
            case SINA_WEIBO:
                "SINA_WEIBO";
            case TENCENT_WEIBO:
                "TENCENT_WEIBO";
            case RENREN_WEIBO:
                "RENREN_WEIBO";
        }
    }

    public static function valueOf(name: String) : Type {
        return switch (name) {
            case "HARRYPHOTO_WEIBO":
                HARRYPHOTO_WEIBO;
            case "SINA_WEIBO":
                SINA_WEIBO;
            case "TENCENT_WEIBO":
                TENCENT_WEIBO;
            case "RENREN_WEIBO":
                RENREN_WEIBO;
            default:
                null;
        }
    }

    public static function allTypes() : Array<Type> {
        return [ SINA_WEIBO, TENCENT_WEIBO, RENREN_WEIBO ];
    }

}
