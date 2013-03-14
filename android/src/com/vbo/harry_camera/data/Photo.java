package com.vbo.harry_camera.data;

public class Photo {

    private String mPath;
    private long mDate;
    public Photo() {
    }

    public Photo(String path) {
        mPath = path;
    }

    public void setDate(long date){
        mDate = date;
    }

    public long getDate() {
        return mDate;
    }

    public void setPath(String path) {
        mPath = path;
    }

    public String getPath() {
        return mPath;
    }
}
