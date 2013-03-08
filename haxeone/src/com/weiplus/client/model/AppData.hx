package com.weiplus.client.model;

class AppData {

    public static inline var IMAGE = "image";

    public var id: String;
    public var type: String; // image/app_id
    public var label: String;
    public var url: String;
    public var image: String; // url
    public var width: Int;
    public var height: Int;

    public function new() {
    }

    public function toString() : String {
        return "AppData{id:" + id +",type:" + type + ",url:" + url + ",image:" + image + ",w:" + width + ",h:" + height + "}";
    }
}
