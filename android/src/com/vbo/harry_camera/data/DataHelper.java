package com.vbo.harry_camera.data;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.BitmapDrawable;
import android.os.AsyncTask;
import android.os.Environment;
import android.util.Log;

import com.weiplus.client.BuildConfig;
import com.weiplus.client.R;
import com.vbo.harry_camera.utils.FileUtil;
import com.vbo.harry_camera.utils.PictureUtil;

import org.apache.http.Header;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.params.HttpParams;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.Timer;
import java.util.TimerTask;

public class DataHelper {

    private static final String TAG = "DataHelper";

    private static boolean sIsResLoaded;
    private static ResLoadingListener sResLoadingListener;
    private static String sCacheDir;
    private static ArrayList<Category> sCategorys = new ArrayList<Category>();
    private static HashMap<Integer, ArrayList<Good>> sGoods = new HashMap<Integer, ArrayList<Good>>();
    private static boolean sIsReadingCache;

    // For Json
    private static final String CATEGORY_PATH =
            "http://s-56378.gotocdn.com/harryphoto/ar/catalogs/list.json";
    private static final String GOODS_PATH =
            "http://s-56378.gotocdn.com/harryphoto/ar/goods/by_catalog/";
    private static final int TIME_OUT_FOR_READ_JSON = 5 * 1000;

    // Json keys
    private static final String KEY_CATEGORYS = "catalogs";
    private static final String KEY_RECORDS = "records";
    private static final String KEY_NAME = "name";
    private static final String KEY_ID = "id";
    private static final String KEY_ICON_PATH = "icon";

    private static final String KEY_GOODS = "goods";
    private static final String KEY_TYPE = "type";
    private static final String KEY_DESCRIPTION = "description";
    private static final String KEY_PRICE = "price";
    private static final String KEY_CID = "cid";
    private static final String KEY_IMAGE = "image";

    //private static final long DATA_RETETION_TIME = 1000 * 60 * 60 * 2;
    private static final long DATA_RETETION_TIME = 1000 * 60;
    private static final String CACHE_FILE_NAME_CATELOGS = "catalogs.idx";

    public static final int[] TEST_THUMBS = {
        R.drawable.test_01_thumb,
        R.drawable.test_02_thumb,
        R.drawable.test_03_thumb,
        R.drawable.test_04_thumb,
        R.drawable.test_05_thumb,
        R.drawable.test_06_thumb,
        R.drawable.test_07_thumb
    };

    public static final int[] TEST_FITTING = {
        R.drawable.test_01_fitting,
        R.drawable.test_02_fitting,
        R.drawable.test_03_fitting,
        R.drawable.test_04_fitting,
        R.drawable.test_05_fitting,
        R.drawable.test_06_fitting,
        R.drawable.test_07_fitting
    };

    private static ArrayList<Ring> sDataCache = new ArrayList<Ring>();
    public static ArrayList<Ring> getData(Context context) {
        if (sDataCache.isEmpty()) {
            initDataCache(context);
        }
        return sDataCache;
    }

    public static void initDataCache(Context context) {
        // XXX Just for test, May be need download from network.
        /*Random random = new Random();
        for (int i = 0; i < TEST_THUMBS.length; i++) {
            Ring ring = new  Ring();
            ring.mPrice = random.nextInt(300);
            //ring.mThumb = ((BitmapDrawable) context.getResources().getDrawable(TEST_THUMBS[i]))
            //        .getBitmap();
            ring.mThumb = TEST_THUMBS[i];
            //ring.mFitting = ((BitmapDrawable) context.getResources().getDrawable(TEST_FITTING[i]))
            //        .getBitmap();
            //ring.mFitting = TEST_FITTING[i];
            sDataCache.add(ring);
        }*/
        // file cache TODO
        initCatelogsCache(context);
    }

    public static void refreshDataCache(Context context) {
        sDataCache.clear();
        initDataCache(context);
    }

    public static void refreshRes(final ResLoadingListener listener) {
        // XXX test code
        Timer timer = new Timer();
        TimerTask task = new  TimerTask() {

            @Override
            public void run() {
                if (listener != null) listener.onResLoaded();
                if (sResLoadingListener != null) sResLoadingListener.onResLoaded();
                sIsResLoaded = true;
            }
        };
        timer.schedule(task, new Random().nextInt(1000) + 1000);
    }

    public static boolean isResLoaded() {
        return sIsResLoaded;
    }

    public static void setResLoadingListener(ResLoadingListener listener) {
        sResLoadingListener = listener;
    }

    public interface ResLoadingListener {
        public void onResLoaded();
    }

    public static ArrayList<Photo> getMyPhotos() {
        ArrayList<Photo> myPhotos = new ArrayList<Photo>();
        final File myPhotosDir = PictureUtil.getMyPhotosDir();
        if (myPhotosDir == null) {
            return null;
        }
        String[] myPhotosPathList = myPhotosDir.list(new FilenameFilter() {
            @Override
            public boolean accept(File dir, String filename) {
                // TODO Auto-generated method stub
                if (dir.equals(myPhotosDir)) {
                    if (filename.endsWith("jpg")) {
                        return true;
                    } else {
                        // ignore other 
                    }
                } else {
                    // ignore sub dir
                }
                return false;
            }
        });
        for (String photoPath : myPhotosPathList) {
            Photo photo = new Photo(myPhotosDir + "/" + photoPath);
            myPhotos.add(photo);
        }
        return myPhotos;
    }

    public static ArrayList<Photo> getPopulars() {
        final File popularsDir = PictureUtil.getPopularsDir();
        ArrayList<Photo> populars = new ArrayList<Photo>();
        String[] popularsPathList = popularsDir.list(new FilenameFilter() {
            
            @Override
            public boolean accept(File dir, String filename) {
                // TODO Auto-generated method stub
                if (dir.equals(popularsDir)) {
                    if (filename.endsWith("jpg")) {
                        return true;
                    } else {
                        // ignore other 
                    }
                } else {
                    // ignore sub dir
                }
                return false;
            }
        });
        for (String photoPath : popularsPathList) {
            Photo photo = new Photo(popularsDir + "/" + photoPath);
            populars.add(photo);
        }
        return populars;
    }

    public static void getCategory(CategoryLoadListener listener) {
        //ArrayList<Category> result = new ArrayList<Category>();
        if (sCategorys.isEmpty()) {
        try {
            URL url = new URL(CATEGORY_PATH);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setReadTimeout(TIME_OUT_FOR_READ_JSON);
            conn.setRequestMethod("GET");
            InputStream inStream = conn.getInputStream();
            byte[] data = readInputSream(inStream);
            String json = new String(data);
            JSONObject jsonMain = new JSONObject(json);
            JSONObject jsonCatelogs = jsonMain.getJSONObject(KEY_CATEGORYS);
            JSONArray jsonRecords = jsonCatelogs.getJSONArray(KEY_RECORDS);
            for (int i = 0; i< jsonRecords.length(); i++) {
                Category oneCategory = new Category();
                JSONObject jsonOneCategory = jsonRecords.getJSONObject(i);
                oneCategory.mName = jsonOneCategory.getString(KEY_NAME);
                oneCategory.mId = jsonOneCategory.getInt(KEY_ID);
                oneCategory.mIconPath = jsonOneCategory.getString(KEY_ICON_PATH);
                    sCategorys.add(oneCategory);
                }
                listener.onCategoryLoaded(sCategorys);
                if (BuildConfig.DEBUG) Log.d(TAG, "json = " + json);
            } catch (MalformedURLException e) {
                Log.w(TAG, "getCategory", e);
            } catch (IOException e) {
                Log.w(TAG, "getCategory", e);
            } catch (JSONException e) {
                Log.w(TAG, "getCategory", e);
            }
        } else {
            listener.onCategoryLoaded(sCategorys);
        }
        /*try {
            URL url = new URL(CATEGORY_PATH);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setReadTimeout(TIME_OUT_FOR_READ_JSON);
            conn.setRequestMethod("GET");
            InputStream inStream = conn.getInputStream();
            byte[] data = readInputSream(inStream);
            String json = new String(data);
            JSONObject jsonMain = new JSONObject(json);
            JSONObject jsonCatelogs = jsonMain.getJSONObject(KEY_CATEGORYS);
            JSONArray jsonRecords = jsonCatelogs.getJSONArray(KEY_RECORDS);
            for (int i = 0; i< jsonRecords.length(); i++) {
                Category oneCategory = new Category();
                JSONObject jsonOneCategory = jsonRecords.getJSONObject(i);
                oneCategory.mName = jsonOneCategory.getString(KEY_NAME);
                oneCategory.mId = jsonOneCategory.getInt(KEY_ID);
                oneCategory.mIconPath = jsonOneCategory.getString(KEY_ICON_PATH);
                result.add(oneCategory);
            }
            listener.onCategoryLoaded(result);
            if (BuildConfig.DEBUG) Log.d(TAG, "json = " + json);
        } catch (MalformedURLException e) {
            Log.w(TAG, "getCategory", e);
        } catch (IOException e) {
            Log.w(TAG, "getCategory", e);
        } catch (JSONException e) {
            Log.w(TAG, "getCategory", e);
        }*/
    }

    public static byte[] readInputSream(InputStream inStream) throws IOException {
        ByteArrayOutputStream outStream = new ByteArrayOutputStream();
        byte[] buffer = new byte[1024];
        int len = 0;
        while ((len = inStream.read(buffer)) != -1) {
            outStream.write(buffer, 0, len);
        }
        inStream.close();
        return outStream.toByteArray();
    }

    public static void getGoods(int id, String categoryName,GoodLoadListener listener) {
        //ArrayList<Good> result = new ArrayList<Good>();
        if (sGoods.isEmpty()) {
        try {
                ArrayList<Good> one = new ArrayList<Good>();
                URL url = new URL(GOODS_PATH + id + ".json");
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setReadTimeout(TIME_OUT_FOR_READ_JSON);
                conn.setRequestMethod("GET");
                InputStream inStream = conn.getInputStream();
                byte[] data = readInputSream(inStream);
                String json = new String(data);
                JSONObject jsonMain = new JSONObject(json);
                JSONObject jsonGoods = jsonMain.getJSONObject(KEY_GOODS);
                JSONArray jsonRecords = jsonGoods.getJSONArray(KEY_RECORDS);
                for (int i = 0; i< jsonRecords.length(); i++) {
                    Good oneGood = new Good();
                    JSONObject jsonOneGood = jsonRecords.getJSONObject(i);
                    oneGood.mName = jsonOneGood.getString(KEY_NAME);
                    oneGood.mType = jsonOneGood.getString(KEY_TYPE);
                    oneGood.mDescription = jsonOneGood.getString(KEY_DESCRIPTION);
                    oneGood.mIconPath = jsonOneGood.getString(KEY_ICON_PATH);
                    oneGood.mPrice = jsonOneGood.getString(KEY_PRICE);
                    oneGood.mCid = jsonOneGood.getInt(KEY_CID);
                    oneGood.mImagePath = jsonOneGood.getString(KEY_IMAGE);
                    oneGood.mId = jsonOneGood.getInt(KEY_ID);
                    one.add(oneGood);
                }
                sGoods.put(id, one);
                listener.onGoodLoaded(one, categoryName);
                if (BuildConfig.DEBUG) Log.d(TAG, "category and json = " + json);
            } catch (MalformedURLException e) {
                Log.w(TAG, "category", e);
            } catch (IOException e) {
                Log.w(TAG, "category", e);
            } catch (JSONException e) {
                Log.w(TAG, "category", e);
            }
        } else {
            ArrayList<Good> one = sGoods.get(id);
            if (one == null) {
                try {
                    one = new ArrayList<Good>();
                    URL url = new URL(GOODS_PATH + id + ".json");
                    HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                    conn.setReadTimeout(TIME_OUT_FOR_READ_JSON);
                    conn.setRequestMethod("GET");
                    InputStream inStream = conn.getInputStream();
                    byte[] data = readInputSream(inStream);
                    String json = new String(data);
                    JSONObject jsonMain = new JSONObject(json);
                    JSONObject jsonGoods = jsonMain.getJSONObject(KEY_GOODS);
                    JSONArray jsonRecords = jsonGoods.getJSONArray(KEY_RECORDS);
                    for (int i = 0; i< jsonRecords.length(); i++) {
                        Good oneGood = new Good();
                        JSONObject jsonOneGood = jsonRecords.getJSONObject(i);
                        oneGood.mName = jsonOneGood.getString(KEY_NAME);
                        oneGood.mType = jsonOneGood.getString(KEY_TYPE);
                        oneGood.mDescription = jsonOneGood.getString(KEY_DESCRIPTION);
                        oneGood.mIconPath = jsonOneGood.getString(KEY_ICON_PATH);
                        oneGood.mPrice = jsonOneGood.getString(KEY_PRICE);
                        oneGood.mCid = jsonOneGood.getInt(KEY_CID);
                        oneGood.mImagePath = jsonOneGood.getString(KEY_IMAGE);
                        oneGood.mId = jsonOneGood.getInt(KEY_ID);
                        one.add(oneGood);
                    }
                    sGoods.put(id, one);
                    listener.onGoodLoaded(one, categoryName);
                    if (BuildConfig.DEBUG) Log.d(TAG, "category and json = " + json);
                } catch (MalformedURLException e) {
                    Log.w(TAG, "category", e);
                } catch (IOException e) {
                    Log.w(TAG, "category", e);
                } catch (JSONException e) {
                    Log.w(TAG, "category", e);
                }
                
            } else {
                listener.onGoodLoaded(one, categoryName);
            }
        }
        /*try {
            URL url = new URL(GOODS_PATH + id + ".json");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setReadTimeout(TIME_OUT_FOR_READ_JSON);
            conn.setRequestMethod("GET");
            InputStream inStream = conn.getInputStream();
            byte[] data = readInputSream(inStream);
            String json = new String(data);
            JSONObject jsonMain = new JSONObject(json);
            JSONObject jsonGoods = jsonMain.getJSONObject(KEY_GOODS);
            JSONArray jsonRecords = jsonGoods.getJSONArray(KEY_RECORDS);
            for (int i = 0; i< jsonRecords.length(); i++) {
                Good oneGood = new Good();
                JSONObject jsonOneGood = jsonRecords.getJSONObject(i);
                oneGood.mName = jsonOneGood.getString(KEY_NAME);
                oneGood.mType = jsonOneGood.getString(KEY_TYPE);
                oneGood.mDescription = jsonOneGood.getString(KEY_DESCRIPTION);
                oneGood.mIconPath = jsonOneGood.getString(KEY_ICON_PATH);
                oneGood.mPrice = jsonOneGood.getString(KEY_PRICE);
                oneGood.mCid = jsonOneGood.getInt(KEY_CID);
                oneGood.mImagePath = jsonOneGood.getString(KEY_IMAGE);
                oneGood.mId = jsonOneGood.getInt(KEY_ID);
                result.add(oneGood);
            }
            listener.onGoodLoaded(result, categoryName);
            if (BuildConfig.DEBUG) Log.d(TAG, "category and json = " + json);
        } catch (MalformedURLException e) {
            Log.w(TAG, "category", e);
        } catch (IOException e) {
            Log.w(TAG, "category", e);
        } catch (JSONException e) {
            Log.w(TAG, "category", e);
        }*/
    }

    public interface CategoryLoadListener{
        public void onCategoryLoaded(ArrayList<Category> categorys);
    }

    public interface GoodLoadListener{
        public void onGoodLoaded(ArrayList<Good> goods, String categoryName);
    }

    public static class ImageDownloadTask extends AsyncTask<String, Integer, Bitmap> {

        @Override
        protected Bitmap doInBackground(String... params) {
            if (BuildConfig.DEBUG)
                Log.d(TAG, "doInBackground:" + params[0]);
            HttpClient httpClient = new DefaultHttpClient();
            HttpGet httpGet = new HttpGet(params[0]);
            InputStream is = null;
            ByteArrayOutputStream baos = null;
            try {  
                HttpResponse httpResponse = httpClient.execute(httpGet);
                printHttpResponse(httpResponse);  
                HttpEntity httpEntity = httpResponse.getEntity();
                long length = httpEntity.getContentLength();
                if (BuildConfig.DEBUG)
                    Log.d(TAG, "content length=" + length);
                is = httpEntity.getContent();
                if (is != null) {
                    baos = new ByteArrayOutputStream();
                    byte[] buf = new byte[128];  
                    int read = -1;
                    int count = 0;
                    while ((read = is.read(buf)) != -1) {
                        baos.write(buf, 0, read);
                        count += read;
                        publishProgress((int ) (count * 1.0f / length));
                    }
                    if (BuildConfig.DEBUG)
                        Log.d(TAG, "count=" + count + " length=" + length);
                    byte[] data = baos.toByteArray();  
                    Bitmap bit = BitmapFactory.decodeByteArray(data, 0, data.length);  
                    return bit;  
                }  
            } catch (ClientProtocolException e) {  
                e.printStackTrace();
            } catch (IOException e) {
                e.printStackTrace();
            } finally {
                try {  
                    if (baos != null) {
                        baos.close();
                    }  
                    if (is != null) {
                        is.close();
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }  
            return null;
        }

        @Override
        protected void onProgressUpdate(Integer... values) {
            super.onProgressUpdate(values);
        }

        private void printHttpResponse(HttpResponse httpResponse) {
            Header[] headerArr = httpResponse.getAllHeaders();
            for (int i = 0; i < headerArr.length; i++) {
                Header header = headerArr[i];
                if (BuildConfig.DEBUG)
                    Log.d(TAG, "name[" + header.getName() + "]value[" + header.getValue() + "]");
            }  
            HttpParams params = httpResponse.getParams();
            if (BuildConfig.DEBUG) {
                Log.d(TAG, String.valueOf(params));
                Log.d(TAG, String.valueOf(httpResponse.getLocale()));
            }
        } 
    }

    public static boolean isExternalStorageAvailable() {
        boolean state = false;
        String extStorageState = Environment.getExternalStorageState();
        if (Environment.MEDIA_MOUNTED.equals(extStorageState)) {
            state = true;
        }
        return state;
    }

    public static boolean isExternalStorageReadOnly() {
        boolean state = false;
        String extStorageState = Environment.getExternalStorageState();
        if (Environment.MEDIA_MOUNTED_READ_ONLY.equals(extStorageState)) {
            state = true;
        }
        return state;
    }

    public static String getInternalCacheDirectory(Context context) {
        String cacheDirPath = null;
        File cacheDir = context.getCacheDir();
        if (cacheDir != null) {
            cacheDirPath = cacheDir.getPath();
        }
        return cacheDirPath;
    }

    public static String getExternalCacheDirectory(Context context) {
        String extCacheDirPath = null;
        File cacheDir = context.getExternalCacheDir();
        if (cacheDir != null) {
            extCacheDirPath = cacheDir.getPath();
        }
        return extCacheDirPath;
    }

    public static boolean initCatelogsCache(Context context) {
        int flag = checkFileCache(context, CACHE_FILE_NAME_CATELOGS);
        if (BuildConfig.DEBUG)
            Log.d(TAG, "checkCache  = " + flag);
        switch (flag) {
            case FLAG_CACHE_AVAILABLE:
                readCache(false);
                break;
            case FLAG_CACHE_EMPTY:
            case FLAG_CACHE_PAST_DUE:
                readCache(true);
                break;
            case FLAG_CACHE_EMPTY_CANT_CREAT:
            case FLAG_CACHE_STORAGE_UNAVAILABLE:
                break;
        }
        return false;
    }

    private static void readCache(boolean fromNetWork) {
        try {
            JSONObject jsonMain = new JSONObject(getCatelogsJsonString(fromNetWork));
            JSONObject jsonCatelogs = jsonMain.getJSONObject(KEY_CATEGORYS);
            JSONArray jsonRecords = jsonCatelogs.getJSONArray(KEY_RECORDS);
            for (int i = 0; i< jsonRecords.length(); i++) {
                Category oneCategory = new Category();
                JSONObject jsonOneCategory = jsonRecords.getJSONObject(i);
                oneCategory.mName = jsonOneCategory.getString(KEY_NAME);
                oneCategory.mId = jsonOneCategory.getInt(KEY_ID);
                oneCategory.mIconPath = jsonOneCategory.getString(KEY_ICON_PATH);
                sCategorys.add(oneCategory);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private static void writeTofile(String filePath, String textToWrite) {
        File catelogs = new File(sCacheDir + "/" + filePath);
        try {
            FileUtil.writeTextFile(catelogs, textToWrite);
        } catch (IOException e) {
            Log.w(TAG, "during write file " + catelogs);
        }
    }

    private static int checkFileCache(Context context, String filePath) {
        if (isExternalStorageAvailable() && !isExternalStorageReadOnly()) {
            sCacheDir = getExternalCacheDirectory(context);
        } else {
            sCacheDir = getInternalCacheDirectory(context);
        }
        if (sCacheDir != null) {
            File catelogs = new File(sCacheDir + "/" + filePath);
            if (catelogs.exists()) {
                long lastModified = catelogs.lastModified();
                if ((System.currentTimeMillis() - lastModified) < DATA_RETETION_TIME) {
                    return FLAG_CACHE_AVAILABLE;
                } else {
                    return FLAG_CACHE_PAST_DUE;
                }
            } else {
                try {
                    catelogs.createNewFile();
                } catch (IOException e) {
                    Log.w(TAG, "during create file " + catelogs.toString());
                    return FLAG_CACHE_EMPTY_CANT_CREAT;
                }
                return FLAG_CACHE_EMPTY;
            }
        } else {
            return FLAG_CACHE_STORAGE_UNAVAILABLE;
        }
    }

    private static String getCatelogsJsonString(boolean fromNetwork) {
        if (fromNetwork) {
            URL url;
            try {
                url = new URL(CATEGORY_PATH);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setReadTimeout(TIME_OUT_FOR_READ_JSON);
                conn.setRequestMethod("GET");
                InputStream inStream = conn.getInputStream();
                byte[] data = readInputSream(inStream);
                return new String(data);
            } catch (MalformedURLException e) {
                e.printStackTrace();
            } catch (IOException e) {
                e.printStackTrace();
            }
        } else {
            File file = new File(sCacheDir + "/" + CACHE_FILE_NAME_CATELOGS);
            try {
                return FileUtil.readTextFile(file);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        return null;
    }

    
    public static final int FLAG_CACHE_AVAILABLE           = 0;
    public static final int FLAG_CACHE_EMPTY               = -1;
    public static final int FLAG_CACHE_PAST_DUE            = -2;
    public static final int FLAG_CACHE_EMPTY_CANT_CREAT    = -3;
    public static final int FLAG_CACHE_STORAGE_UNAVAILABLE = -4;
}
