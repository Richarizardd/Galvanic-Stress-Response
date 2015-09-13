package org.centum.android.stressmonitor.network;

import android.content.Context;

import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonObjectRequest;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by Phani on 9/12/2015.
 */
public class DataService {

    private long[] timeData = new long[0];
    private double[] voltData = new double[0];
    private String currentMood = "";

    public void requestUpdate(Context context) {
        RequestQueue queue = Volley.newRequestQueue(context);
        String dataURL = "https://api.mongolab.com/api/1/databases/todolist/collections/gsr/sensor_data?apiKey=kACN9gq9YK54jjKSEiil3giWBDwlzano";
        String moodURL = "https://api.mongolab.com/api/1/databases/todolist/collections/gsr/currentmood?apiKey=kACN9gq9YK54jjKSEiil3giWBDwlzano";

        JsonObjectRequest moodReq = new JsonObjectRequest(moodURL, null, new Response.Listener<JSONObject>() {
            @Override
            public void onResponse(JSONObject jsonObject) {
                try {
                    currentMood = jsonObject.getString("mood");
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        }, new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError volleyError) {

            }
        });

        JsonObjectRequest request = new JsonObjectRequest(dataURL, null, new Response.Listener<JSONObject>() {
            @Override
            public void onResponse(JSONObject jsonObject) {
                try {
                    JSONArray voltages = jsonObject.getJSONArray("voltage");
                    JSONArray times = jsonObject.getJSONArray("time");

                    voltData = new double[voltages.length()];
                    timeData = new long[times.length()];

                    for(int i = 0; i < voltData.length; i++){
                        voltData[i] = voltages.getDouble(i);
                    }
                    for(int i = 0; i < timeData.length; i++){
                        timeData[i] = times.getLong(i);
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                }

            }
        }, new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError volleyError) {

            }
        });
        queue.add(request);
        queue.add(moodReq);
    }

    public long[] getTimes() {
        return timeData;
    }

    public double[] getVolts() {
        return voltData;
    }

    public String getCurrentMood() {
        return currentMood;
    }
}
