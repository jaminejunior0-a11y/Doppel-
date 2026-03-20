package com.doppel.ui;

import android.app.Activity;
import android.os.Bundle;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Button;
import android.view.View;
import android.graphics.Color;

public class SecretLauncherActivity extends Activity {
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(50, 50, 50, 50);
        layout.setBackgroundColor(Color.BLACK);
        
        TextView title = new TextView(this);
        title.setText("🔐 SECRET MODE");
        title.setTextColor(Color.GREEN);
        title.setTextSize(28);
        title.setGravity(1);
        layout.addView(title);
        
        TextView content = new TextView(this);
        content.setText(
            "Advanced Features:\n\n" +
            "• Native Property Hooks Active\n" +
            "• Binder Interceptor Ready\n" +
            "• Identity Generator Online\n" +
            "• System Call Monitor\n\n" +
            "This is a proof-of-concept for\n" +
            "Android system interoperability."
        );
        content.setTextColor(Color.WHITE);
        content.setPadding(20, 40, 20, 40);
        layout.addView(content);
        
        Button closeBtn = new Button(this);
        closeBtn.setText("EXIT SECRET MODE");
        closeBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });
        layout.addView(closeBtn);
        
        setContentView(layout);
    }
}
