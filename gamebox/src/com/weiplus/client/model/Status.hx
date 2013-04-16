package com.weiplus.client.model;


class Status {

    public var id: String;
    public var text: String;
    public var createdAt: Date;

    public var appData: AppData; // url
    public var user: User;
    public var retweetStatus: Status;
    public var repostCount: Int;
    public var commentCount: Int;
    public var favoriteCount: Int;
    public var praiseCount: Int;
    public var reposts: Array<Retweet>;
    public var comments: Array<Comment>;
    public var geo: Geo;
    public var mark: Int;

    public var isNew: Bool; // read or not
    public var makerData: Dynamic = null;
    public var praised: Bool = false;

    public function new() {
    }

    public function toString() : String {
        return "Status{id:" + id +",text:" + text + ",createdAt:" + createdAt + ",user:\n" + user + "\n,appData:\n" + appData + "\n}";
    }

}
