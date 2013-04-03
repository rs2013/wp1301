package com.weiplus.client.model;

class User {

    public var id: String;
    public var name: String;
    public var createdAt: Date;
    public var profileUrl: String; // url
    public var profileImage: String; // url
    public var lastVisitAt: Date;

    public var followerCount: Int;
    public var postCount: Int;
    public var friendCount: Int;

    public function new() {
    }

    public function toString() : String {
        return "User{id:" + id +",name:" + name + ",createdAt:" + createdAt + ",profileUrl:" + profileUrl + ",profileImage:" + profileImage + "}";
    }
}
