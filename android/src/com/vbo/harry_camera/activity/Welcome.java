package com.vbo.harry_camera.activity;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.hardware.Camera;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.support.v4.view.PagerAdapter;
import android.support.v4.view.ViewPager;
import android.support.v4.view.ViewPager.LayoutParams;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;
import android.widget.BaseAdapter;
import android.widget.GridView;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.weiplus.client.R;
import com.vbo.harry_camera.data.DataHelper;
import com.vbo.harry_camera.data.Option;
import com.vbo.harry_camera.data.Photo;
import com.vbo.harry_camera.utils.CameraUtil;
import com.vbo.harry_camera.utils.PictureUtil;

import java.io.File;
import java.util.ArrayList;
import java.util.Date;

public class Welcome extends Activity {

    private static final int HANDLER_SPLASH_ANIMATION_START = 0;

    private static final int MY_PHOTOS_PAGE_INDEX = 0;
    private static final int POPULAR_PAGE_INDEX = 1;
    private static final int OPTIONS_PAGE_INDEX = 2;

    private static final int OPTION_SHREA_ID = 0;
    private static final int OPTION_UPDATE_ID = 1;
    private static final int OPTION_ABOUT_ID = 2;
    ImageView mSplash;
    Animation mSplashAnimation;
    //ViewGroup mMainView;
    ViewPager mViewPager;
    private LayoutInflater mLayoutInflater;
    private RelativeLayout mMyPhotosPage;
    private RelativeLayout mPopularPage;
    private RelativeLayout mOptionPage;
    private RelativeLayout mEmulatedActionBar;
    private RelativeLayout mBottonBar;
    private ListView mPhotosList;
    private GridView mPopularGrid;
    private ListView mOptionList;
    private ArrayList<View> mPages;
    private PagesAdapter mPagesAdapter;

    private ArrayList<Photo> mMyPhotos;
    private ArrayList<Photo> mPopulars;
    private ArrayList<Option> mOptions;
    Handler mHandler = new Handler() {

        @Override
        public void handleMessage(Message msg) {
            super.handleMessage(msg);
            switch (msg.what) {
                case HANDLER_SPLASH_ANIMATION_START:
                    mSplash.startAnimation(mSplashAnimation);
                    break;
            }
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_welcome);
        mLayoutInflater = getLayoutInflater();
        mPages = new ArrayList<View>();
        initView();
        if (DataHelper.isResLoaded()) {
            mSplash.startAnimation(mSplashAnimation);
        } else {
            DataHelper.setResLoadingListener(new DataHelper.ResLoadingListener() {

                @Override
                public void onResLoaded() {
                    mHandler.sendEmptyMessage(HANDLER_SPLASH_ANIMATION_START);
                }
            });
        };
    }

    private void initView() {
        mSplash = (ImageView) findViewById(R.id.splash);
        mSplashAnimation = new AlphaAnimation(1, 0);
        mSplashAnimation.setDuration(500);
        mSplashAnimation.setAnimationListener(new Animation.AnimationListener() {

            @Override
            public void onAnimationStart(Animation animation) {
                //
            }
            
            @Override
            public void onAnimationRepeat(Animation animation) {
                //
            }
            
            @Override
            public void onAnimationEnd(Animation animation) {
                if (mSplash != null)
                    mSplash.setVisibility(View.GONE);
                /*if (mMainView != null)
                    mMainView.setVisibility(View.VISIBLE);*/
                if (mViewPager != null) {
                    mViewPager.setVisibility(View.VISIBLE);
                }
                if (mEmulatedActionBar != null) {
                    mEmulatedActionBar.setVisibility(View.VISIBLE);
                }
                if (mBottonBar != null) {
                    mBottonBar.setVisibility(View.VISIBLE);
                }
                setData();
            }
        });
        //mMainView = (ViewGroup) findViewById(R.id.main_view);
        mEmulatedActionBar = (RelativeLayout) findViewById(R.id.emulated_action_bar);
        mBottonBar = (RelativeLayout) findViewById(R.id.bottom_bar);
        mViewPager = (ViewPager) findViewById(R.id.pager);
        TextView actionBarTitle = (TextView) mEmulatedActionBar.findViewById(R.id.action_bar_title);
        actionBarTitle.setText(R.string.app_name);
        ImageView bottomButton = (ImageView) mBottonBar.findViewById(R.id.bottom_button);
        bottomButton.setImageResource(R.drawable.home);
        bottomButton.setOnClickListener(new View.OnClickListener() {
            
            @Override
            public void onClick(View v) {
                Intent cameraStarter = new Intent(Welcome.this, CameraActivity.class);
                startActivity(cameraStarter);
            }
        });
        mMyPhotosPage = (RelativeLayout) mLayoutInflater.inflate(R.layout.my_photos, null);
        mPopularPage = (RelativeLayout) mLayoutInflater.inflate(R.layout.popular, null);
        mOptionPage = (RelativeLayout) mLayoutInflater.inflate(R.layout.options, null);
        mPhotosList = (ListView) mMyPhotosPage.findViewById(R.id.my_photos_list);
        mPopularGrid = (GridView) mPopularPage.findViewById(R.id.popular_grid);
        mOptionList = (ListView) mOptionPage.findViewById(R.id.options);
        mPages.add(MY_PHOTOS_PAGE_INDEX, mMyPhotosPage);
        mPages.add(POPULAR_PAGE_INDEX, mPopularPage);
        mPages.add(OPTIONS_PAGE_INDEX, mOptionPage);
        mPagesAdapter = new PagesAdapter(mPages);
        mViewPager.setAdapter(mPagesAdapter);
    }

    private void setData() {
        mMyPhotos = DataHelper.getMyPhotos();
        mPopulars = DataHelper.getPopulars();
        mOptions = new ArrayList<Option>();
        Option optionShare = new Option(getString(R.string.option_content_share), null, OPTION_SHREA_ID);
        Option optionUpdate = new Option(getString(R.string.option_content_update),
                getString(R.string.option_mark_update), OPTION_UPDATE_ID);
        Option optionAbout = new Option(getString(R.string.option_content_about), null, OPTION_ABOUT_ID);
        mOptions.add(optionShare);
        mOptions.add(optionUpdate);
        mOptions.add(optionAbout);
        MyPhotosAdapter myPhotosAdapter = new MyPhotosAdapter(mMyPhotos);
        PopularsAdapter popularsAdapter = new PopularsAdapter(mPopulars);
        OptionsAdapter optionAdapter = new OptionsAdapter(mOptions);
        mPhotosList.setAdapter(myPhotosAdapter);
        mPopularGrid.setAdapter(popularsAdapter);
        mOptionList.setAdapter(optionAdapter);
    }

    private class PagesAdapter extends PagerAdapter {

        private ArrayList<View> mPages;
        public PagesAdapter(ArrayList<View> pages) {
            mPages = pages;
        }

        @Override
        public int getCount() {
            return mPages != null ? mPages.size() : 0;
        }

        @Override
        public boolean isViewFromObject(View arg0, Object arg1) {
            return arg0 == arg1;
        }

        @Override
        public void destroyItem(ViewGroup container, int position, Object object) {
            container.removeView(mPages.get(position));
        }

        @Override
        public Object instantiateItem(ViewGroup container, int position) {
            if (mPages.get(position) == null) {
                return null;
            }
            container.addView(mPages.get(position), 0);
            return mPages.get(position);
        }
    }

    private class MyPhotosAdapter extends BaseAdapter {

        private ArrayList<Photo> mPhotos;

        public MyPhotosAdapter(ArrayList<Photo> photos) {
            mPhotos = photos;
        }

        @Override
        public int getCount() {
            return mPhotos.size();
        }

        @Override
        public Object getItem(int position) {
            return null;
        }

        @Override
        public long getItemId(int position) {
            return 0;
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            final Photo photo = mPhotos.get(position);
            MyPhotosViewHolder holder;
            if (convertView == null) {
                convertView = mLayoutInflater.inflate(R.layout.my_photos_item, null);
                holder = new MyPhotosViewHolder();
                holder.mDate = (TextView) convertView.findViewById(R.id.my_photo_date);
                holder.mPhotoPic = (ImageView) convertView.findViewById(R.id.my_photo_image);
                convertView.setTag(holder);
            } else {
                holder = (MyPhotosViewHolder) convertView.getTag();
            }
            holder.mDate.setText(new Date(photo.getDate()).toLocaleString());
            holder.mPhotoPic.setImageBitmap(PictureUtil.decodePicToBitmap(photo.getPath(), PictureUtil.PIC_SIZE_LARGE));
            convertView.setOnClickListener(new View.OnClickListener() {

                @Override
                public void onClick(View v) {
                    Intent intent = new Intent(Intent.ACTION_VIEW);
                    intent.setDataAndType(Uri.fromFile(new File(photo.getPath())), "image/jpeg");
                    startActivity(intent);
                }
            });
            return convertView;
        }
    }

    private class PopularsAdapter extends BaseAdapter {

        private ArrayList<Photo> mPopulars;

        public PopularsAdapter(ArrayList<Photo> populars) {
            mPopulars = populars;
        }

        @Override
        public int getCount() {
            return mPopulars.size();
        }

        @Override
        public Object getItem(int position) {
            return null;
        }

        @Override
        public long getItemId(int position) {
            return 0;
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            final Photo popular = mPopulars.get(position);
            PopularsViewHolder holder;
            if (convertView == null) {
                convertView = mLayoutInflater.inflate(R.layout.popular_item, null);
                holder = new PopularsViewHolder();
                holder.mPhotoPic = (ImageView) convertView.findViewById(R.id.popular_image);
                convertView.setTag(holder);
            } else {
                holder = (PopularsViewHolder) convertView.getTag();
            }
            holder.mPhotoPic.setImageBitmap(PictureUtil.decodePicToBitmap(popular.getPath(), PictureUtil.PIC_SIZE_NORMAL));
            convertView.setOnClickListener(new View.OnClickListener() {

                @Override
                public void onClick(View v) {
                    Intent intent = new Intent(Intent.ACTION_VIEW);
                    intent.setDataAndType(Uri.fromFile(new File(popular.getPath())), "image/jpeg");
                    startActivity(intent);
                }
            });
            return convertView;
        }
    }

    private class OptionsAdapter extends BaseAdapter {

        private ArrayList<Option> mOptions;

        public OptionsAdapter(ArrayList<Option> options) {
            mOptions = options;
        }

        @Override
        public int getCount() {
            return mOptions.size();
        }

        @Override
        public Object getItem(int position) {
            return null;
        }

        @Override
        public long getItemId(int position) {
            return 0;
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            Option option = mOptions.get(position);
            OptionsViewHolder holder;
            if (convertView == null) {
                convertView = mLayoutInflater.inflate(R.layout.options_item, null);
                holder = new OptionsViewHolder();
                holder.mContent = (TextView) convertView.findViewById(R.id.content);
                holder.mMark = (TextView) convertView.findViewById(R.id.mark);
                convertView.setTag(holder);
            } else {
                holder = (OptionsViewHolder) convertView.getTag();
            }
            holder.mContent.setText(option.getContent());
            holder.mMark.setText(option.getMark());
            return convertView;
        }
        
    }

    static class MyPhotosViewHolder {
        TextView mDate;
        ImageView mPhotoPic;
    }

    static class PopularsViewHolder {
        ImageView mPhotoPic;
    }

    static class OptionsViewHolder {
        TextView mContent;
        TextView mMark;
    }
}
