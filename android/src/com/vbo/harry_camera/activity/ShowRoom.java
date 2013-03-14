package com.vbo.harry_camera.activity;

import android.os.Bundle;
import android.app.Activity;
import android.content.Intent;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.Button;
import android.widget.GridView;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.weiplus.client.R;
import com.vbo.harry_camera.data.DataHelper;
import com.vbo.harry_camera.data.GridAdapter;
import com.vbo.harry_camera.data.Ring;
import com.vbo.harry_camera.utils.CameraUtil;

import java.util.ArrayList;

public class ShowRoom extends Activity implements OnClickListener{

    private ViewGroup mHeader;
    private Button mHeaderButton1;
    private Button mHeaderButton2;
    private Button mHeaderButton3;
    private ViewGroup mFooter;
    private Button mFooterButton;
    private TextView mFooterTextView;
    private GridView mShowcase;
    private ArrayList<Ring> mRings;
    private GridAdapter mAdapter;
    private boolean mNoCamara;

    public static final String RINGS_SELECTED_ID = "rings_selected_id";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_show_room);
        if (CameraUtil.setCurrentMode(true) < 0) {
            Toast.makeText(this, R.string.no_camera, Toast.LENGTH_SHORT).show();
            mNoCamara = true;
        }
        initView();
        initData();
    }

    private void initView() {
        mHeader = (ViewGroup) findViewById(R.id.header);
        mHeaderButton1 = (Button) findViewById(R.id.btn_header1);
        mHeaderButton2 = (Button) findViewById(R.id.btn_header2);
        mHeaderButton3 = (Button) findViewById(R.id.btn_header3);
        mFooter = (ViewGroup) findViewById(R.id.footer);
        mFooterButton = (Button) findViewById(R.id.btn_footer);
        mShowcase = (GridView) findViewById(R.id.showcase);
        mFooterTextView = (TextView) findViewById(R.id.footer_text);
        if (mNoCamara) {
            mFooterTextView.setText(R.string.no_camera);
        }
    }

    @SuppressWarnings("unchecked")
    private void initData() {
        mRings = (ArrayList<Ring>) DataHelper.getData(this).clone();
        mAdapter = new GridAdapter(this, mRings);
        mShowcase.setAdapter(mAdapter);
        mHeader.setOnClickListener(this);
        mHeaderButton1.setOnClickListener(this);
        mHeaderButton2.setOnClickListener(this);
        mHeaderButton3.setOnClickListener(this);
        mFooter.setOnClickListener(this);
        mFooterButton.setOnClickListener(this);
        mShowcase.setOnItemClickListener(new OnItemClickListener() {

            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                Ring ring = mRings.get(position);
                ring.mIsSelected = !ring.mIsSelected;
                ImageView check = (ImageView)view.findViewById(R.id.check);
                if (ring.mIsSelected == true) {
                    check.setVisibility(View.VISIBLE);
                } else {
                    check.setVisibility(View.INVISIBLE);
                }
                boolean hasSelected = hasSelected();
                mFooterButton.setVisibility((!mNoCamara && hasSelected) ? View.VISIBLE : View.GONE);
                mFooterTextView.setVisibility((!mNoCamara && hasSelected) ? View.GONE : View.VISIBLE);
            }
        });
    }

    private boolean hasSelected() {
        for (Ring ring : mRings) {
            if (ring.mIsSelected == true) {
                return true;
            }
        }
        return false;
    }
    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.activity_show_room, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        int id = item.getItemId();
        switch (id) {
            case R.id.menu_about:
                // TODO
                break;
            case R.id.menu_settings:
                // TODO
                break;
        }
        return super.onOptionsItemSelected(item);
    }

    @Override
    public void onClick(View v) {
        switch (v.getId()) {
            case R.id.btn_header1:
                // TODO
                break;
            case R.id.btn_header2:
                // TODO
                break;
            case R.id.btn_header3:
                // TODO
                break;
            case R.id.btn_footer:
                Intent intent = new Intent(ShowRoom.this, FittingRoom.class);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
                confirmDataSelected();
                intent.putExtra(RINGS_SELECTED_ID, confirmDataSelected());
                startActivity(intent);
                break;
        }
    }

    private long[] confirmDataSelected() {
        ArrayList<Integer> resultList = new ArrayList<Integer>();
        for (int i = 0; i < mRings.size(); i++) {
            if (mRings.get(i).mIsSelected) {
                resultList.add(i);
            }
        }
        long[] result = new long[resultList.size()];
        for (int i = 0; i < result.length; i++) {
            result[i] = resultList.get(i);
        }
        return result;
    }

    @Override
    protected void onStart() {
        super.onStart();
        boolean hasSelected = hasSelected();
        mFooterButton.setVisibility((!mNoCamara && hasSelected) ? View.VISIBLE : View.GONE);
        mFooterTextView.setVisibility((!mNoCamara && hasSelected) ? View.GONE : View.VISIBLE);
    }
}
