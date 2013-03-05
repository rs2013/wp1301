package org.haxe.nme;

import android.util.Log;

// Wrapper for library

public class NME {

    public static int onDeviceOrientationUpdate(int orientation) {
        Log.i("FakeNME", "onDeviceOrientationUpdate");
        return 0;
    }

    public static int onNormalOrientationFound(int orientation) {
        Log.i("FakeNME", "onNormalOrientationFound");
        return 0;
    }

    public static int onOrientationUpdate(float x, float y, float z) {
        Log.i("FakeNME", "onOrientationUpdate");
        return 0;
    }

    public static int onAccelerate(float x, float y, float z) {
        Log.i("FakeNME", "onAccelerate");
        return 0;
    }

    public static int onTouch(int type, float x, float y, int id, float sizeX,
            float sizeY) {
        Log.i("FakeNME", "onTouch");
        return 0;
    }

    public static int onResize(int width, int height) {
        Log.i("FakeNME", "onResize");
        return 0;
    }

    public static int onTrackball(float x, float y) {
        Log.i("FakeNME", "onTrackball");
        return 0;
    }

    public static int onKeyChange(int inCode, boolean inIsDown) {
        Log.i("FakeNME", "onKeyChange");
        return 0;
    }

    public static int onRender() {
        Log.i("FakeNME", "onRender");
        return 0;
    }

    public static int onPoll() {
        Log.i("FakeNME", "onPoll");
        return 0;
    }

    public static double getNextWake() {
        Log.i("FakeNME", "getNextWake");
        return 0;
    }

    public static int onActivity(int inState) {
        Log.i("FakeNME", "onActivity");
        return 0;
    }

    public static void onCallback(long inHandle) {
        Log.i("FakeNME", "onCallback");
    }

    public static Object callObjectFunction(long inHandle, String function,
            Object[] args) {
        Log.i("FakeNME", "callObjectFunction");
        return null;
    }

    public static double callNumericFunction(long inHandle, String function,
            Object[] args) {
        Log.i("FakeNME", "callNumericFunction");
        return 0;
    }

    public static void releaseReference(long inHandle) {
        Log.i("FakeNME", "releaseReference");
    }
}
