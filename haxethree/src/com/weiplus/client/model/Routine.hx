package com.weiplus.client.model;

using com.roxstudio.i18n.I18n;

class Routine {

    public var id: String;
    public var type: String;
    public var user: User;
    public var follower: User;
    public var createdAt: Date;
    public var oid: String;
    public var digest: String;

    public function new() {
    }

    

    public function getMessage() : String {
        return switch (type) {
            case "COMMENTS_CREATE":
                follower.name + "对您的作品发表了评论：".i18n() + digest;
            case "STATUSES_PRAISE":
                follower.name + "称赞了您的作品。".i18n();
            case "FRIENDSHIPS_CREATE":
                if (follower.id == RoutineScreen.ADMIN_UID) {
                    follower.name + ": " + digest;
                } else {
                    follower.name + "已开始关注您。".i18n();
                }
            default:
                "";
        }
    }
}
