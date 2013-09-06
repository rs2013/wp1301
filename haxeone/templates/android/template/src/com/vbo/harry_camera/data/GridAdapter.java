package com.vbo.harry_camera.data;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.ImageView;
import android.widget.TextView;

import com.weiplus.client.R;

import java.text.DecimalFormat;
import java.util.ArrayList;

public class GridAdapter extends BaseAdapter {

    private Context mContext;
    private ArrayList<Ring> mData;
    private LayoutInflater mInflater;
    private DecimalFormat mFormater;
    private static final String PRICE_FORMAT = ".00";
    public GridAdapter(Context context, ArrayList<Ring> data) {
        mContext = context;
        mData = data;
        mInflater = LayoutInflater.from(mContext);
        mFormater = new DecimalFormat(PRICE_FORMAT);
    }

    @Override
    public int getCount() {
        return mData.size();
    }

    @Override
    public Object getItem(int position) {
        return mData.get(position);
    }

    @Override
    public long getItemId(int position) {
        return position;
    }

    @Override
    public View getView(int positon, View convertView, ViewGroup parent) {
        ViewHolder holder;
        Ring ring = mData.get(positon);
        if (convertView == null) {
            convertView = mInflater.inflate(R.layout.ring_grid_item, null);
            holder = new ViewHolder();
            holder.mThumb = (ImageView) convertView.findViewById(R.id.thumb);
            holder.mPirce = (TextView) convertView.findViewById(R.id.price);
            holder.mCheck = (ImageView) convertView.findViewById(R.id.check);
            convertView.setTag(holder);
        } else {
            holder = (ViewHolder) convertView.getTag();
        }
        // TODO 
        //holder.mThumb.setImageBitmap(ring.mThumb);
        holder.mThumb.setImageResource(ring.mThumb);
        holder.mPirce.setText(mContext.getString(R.string.content_item_price,
                mFormater.format(ring.mPrice)));
        if (holder.mCheck != null) {
        	holder.mCheck.setVisibility(ring.mIsSelected ? View.VISIBLE : View.INVISIBLE);
        }
        return convertView;
    }

    static class ViewHolder{
        ImageView mThumb;
        TextView mPirce;
        ImageView mCheck;
    }
}
