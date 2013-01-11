package com.weiplus.client.model;


class Status {

    public var id: String;
    public var text: String;
    public var createdAt: Date;

    public var appData: AppData; // url
    public var user: User;
    public var retweetStatus: Status;
    public var repostsCount: Int;
    public var commentsCount: Int;
    public var reposts: Array<Retweet>;
    public var comments: Array<Comment>;
    public var geo: Geo;

    public var isNew: Bool; // read or not

    public function new() {
    }

    public function toString() : String {
        return "Status{id:" + id +",text:" + text + ",createdAt:" + createdAt + ",user:\n" + user + "\n,appData:\n" + appData + "\n}";
    }

}
