package com.harryphoto.api;

import java.util.ArrayList;

import android.text.TextUtils;

public class HpParameters {

    private ArrayList<String> mKeys = new ArrayList<String>();
    private ArrayList<String[]> mValues = new ArrayList<String[]>();

    public HpParameters(){
        
    }
    
    public void add(String key, boolean isFile, String value, int index) {
        if (index < 0) index = mKeys.size();
        if (!TextUtils.isEmpty(key) && index <= mKeys.size()) {
            mKeys.add(index, key);
            mValues.add(index, new String[] { isFile ? "F" : "S", value } );
        }
    }
    
    public void add(String key, String value) {
        add(key, false, value, -1);
    }
    
    public void add(String key, int value) {
        add(key, false, String.valueOf(value), -1);
    }
    public void add(String key, long value) {
        add(key, false, String.valueOf(value), -1);
    }
    
    public void remove(String key) {
        int firstIndex = mKeys.indexOf(key);
        if (firstIndex >= 0) {
            this.mKeys.remove(firstIndex);
            this.mValues.remove(firstIndex);
        }
    }
    
    public void remove(int i) {
        if (i < mKeys.size()) {
            mKeys.remove(i);
            this.mValues.remove(i);
        }
        
    }
    
    public boolean hasFile() {
        for (String[] pair: mValues) {
            if (pair[0] == "F") return true;
        }
        return false;
    }
    
    public String getKey(int index) {
        if(index >= 0 && index < this.mKeys.size()){
            return this.mKeys.get(index);
        }
        return "";
    }
    
    
    public String getValue(String key) {
        int index = mKeys.indexOf(key);
        if (index >= 0 && index < this.mKeys.size()) {
            return this.mValues.get(index)[1];
        } else {
            return null;
        }

    }
    
    public boolean isFile(int index) {
        if (index >= 0 && index < this.mKeys.size()) {
            String rlt = this.mValues.get(index)[0];
            return rlt == "F";
        }
        return false;
    }
    
    public String getValue(int index) {
        if (index >= 0 && index < this.mKeys.size()) {
            String rlt = this.mValues.get(index)[1];
            return rlt;
        } else {
            return null;
        }

    }    
    
    public int size() {
        return mKeys.size();
    }

    public void addAll(HpParameters parameters) {
        for (int i = 0; i < parameters.size(); i++) {
            this.add(parameters.getKey(i), parameters.getValue(i));
        }

    }

    public void clear() {
        this.mKeys.clear();
        this.mValues.clear();
    }

}
