package com.weiplus.client.model;

class Routine {

    public var id: String;
    public var type: String;
    public var user: User;
    public var follower: User;
    public var createAt: Date;
    public var oid: String;
    public var digest: String;

    public function new() {
    }

    public function getMessage() : String {
        return switch (type) {
            case "COMMENTS_CREATE":
                follower.name + "对您的作品发表了评论：" + digest;
            case "STATUSES_PRAISE":
                follower.name + "称赞了您的作品。";
            case "FRIENDSHIPS_CREATE":
                follower.name + "已开始关注您。";
            default:
                "";
        }
    }
}
