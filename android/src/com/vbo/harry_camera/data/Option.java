package com.vbo.harry_camera.data;

public class Option {

    private String mContent;
    private int mId;
    private String mMark;
    public Option(){
    }

    public Option(String content, String mark, int id) {
        mContent = content;
        mMark = mark;
        mId= id;
    }

    public void setContent(String content) {
        mContent = content;
    }

    public void setMark(String mark) {
        mMark = mark;
    }

    public void setId(int id) {
        mId = id;
    }

    public String getContent() {
        return mContent;
    }

    public String getMark() {
        return mMark;
    }

    public int getId() {
        return mId;
    }
}
