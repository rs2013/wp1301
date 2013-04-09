package com.weiplus.client.model;

class Friendship {

    public var id: String;
    public var uid: String;
    public var name: String;
    public var avatar: String; // url
    public var fid: String; // friend uid
    public var friendName: String; // url
    public var friendAvatar: String;
    public var createdAt: Date;
    public var status: String;

    public function new() {
    }

}
