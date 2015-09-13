package org.centum.android.stressmonitor;

import android.graphics.Color;
import android.os.AsyncTask;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.FrameLayout;
import android.widget.TextView;

import com.jjoe64.graphview.GraphView;
import com.jjoe64.graphview.GraphViewSeries;
import com.jjoe64.graphview.LineGraphView;

import org.centum.android.stressmonitor.network.DataService;

public class MainActivity extends AppCompatActivity {

    private FrameLayout graphFrameLayout;
    private TextView textView;
    private LineGraphView graphView;
    private GraphViewSeries series;
    private DataService dataService = new DataService();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        graphFrameLayout = (FrameLayout) findViewById(R.id.graphFrameLayout);
        textView = (TextView) findViewById(R.id.moodTV);
        initPlot();
        startUpdate();
    }

    private void startUpdate() {
        new AsyncTask<Void, Void, Void>() {

            @Override
            protected Void doInBackground(Void... params) {
                while (true) {
                    dataService.requestUpdate(MainActivity.this);
                    try {
                        Thread.sleep(1000);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            long times[] = dataService.getTimes();
                            double volts[] = dataService.getVolts();
                            GraphView.GraphViewData data[] = new GraphView.GraphViewData[times.length];
                            for(int i = 0; i < times.length; i++){
                                data[i] = new GraphView.GraphViewData(times[i], volts[i]);
                            }
                            series.resetData(data);
                            textView.setText(dataService.getCurrentMood());
                        }
                    });
                }
            }
        }.execute();
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    private void initPlot() {
        graphView = new LineGraphView(this, "");
        graphView.setDrawBackground(false);
        //graphView.setViewPort(1, 2000);
        graphView.setScalable(false);
        graphView.setScrollable(true);
        //graphView.setManualYAxis(true);
        //graphView.setManualYAxisBounds(5, 0);
        graphView.getGraphViewStyle().setHorizontalLabelsColor(Color.TRANSPARENT);
        graphView.getGraphViewStyle().setGridColor(Color.rgb(200, 200, 200));

        series = new GraphViewSeries(new GraphView.GraphViewData[]{new GraphView.GraphViewData(1, 0d)});
        series.getStyle().color = Color.parseColor("#33B5E5");
        series.getStyle().thickness = 5;
        graphView.addSeries(series);

        graphFrameLayout.addView(graphView);
    }
}
