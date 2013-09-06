package com.weiplus.client.model;

class Comment {

    public var id: String;
    public var user: User;
    public var commenter: User;
    public var text: String;
    public var createdAt: Date;

    public function new() {
    }

}
