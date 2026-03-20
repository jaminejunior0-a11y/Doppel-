package com.doppel;

import android.app.Activity;
import android.os.Bundle;
import android.widget.*;
import android.view.View;
import android.graphics.Color;
import android.content.Intent;

// Import our new modules
import com.doppel.identity.IdentityGenerator;
import com.doppel.hooks.BinderInterceptor;
import com.doppel.ui.SecretLauncherActivity;

public class MainActivity extends Activity {
    
    static {
        System.loadLibrary("proputils");
    }
    
    // Native methods
    public native String getSystemProperty(String key);
    public native boolean initNative();
    public native String getPropHook(String key);
    
    // UI Components
    private LinearLayout mainLayout;
    private TextView statusText;
    private Button secretButton;
    private int tapCount = 0;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        mainLayout = new LinearLayout(this);
        mainLayout.setOrientation(LinearLayout.VERTICAL);
        mainLayout.setPadding(50, 50, 50, 50);
        
        // Title
        TextView title = new TextView(this);
        title.setText("⚡ DOPPEL ⚡");
        title.setTextSize(32);
        title.setTextColor(Color.parseColor("#FF6B6B"));
        title.setGravity(1);
        mainLayout.addView(title);
        
        // Subtitle
        TextView subtitle = new TextView(this);
        subtitle.setText("System Identity Framework");
        subtitle.setTextSize(16);
        subtitle.setGravity(1);
        subtitle.setPadding(0, 0, 0, 40);
        mainLayout.addView(subtitle);
        
        // Status Display
        statusText = new TextView(this);
        statusText.setText("System Ready");
        statusText.setTextSize(14);
        statusText.setPadding(20, 20, 20, 20);
        statusText.setBackgroundColor(Color.parseColor("#F0F0F0"));
        mainLayout.addView(statusText);
        
        // Test Button
        Button testButton = new Button(this);
        testButton.setText("🔍 Test Native Hook");
        testButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                testNativeHooks();
            }
        });
        mainLayout.addView(testButton);
        
        // Identity Button
        Button identityButton = new Button(this);
        identityButton.setText("🆔 Generate Identity");
        identityButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showIdentity();
            }
        });
        mainLayout.addView(identityButton);
        
        // Binder Button
        Button binderButton = new Button(this);
        binderButton.setText("🔄 Binder Interceptor");
        binderButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startBinderService();
            }
        });
        mainLayout.addView(binderButton);
        
        // Secret Launcher (hidden)
        secretButton = new Button(this);
        secretButton.setText("⚙️");
        secretButton.setVisibility(View.GONE);
        secretButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                launchSecretMode();
            }
        });
        mainLayout.addView(secretButton);
        
        // Easter egg area (tap 7 times)
        TextView easterEgg = new TextView(this);
        easterEgg.setText("v1.0.0");
        easterEgg.setTextSize(12);
        easterEgg.setGravity(1);
        easterEgg.setPadding(0, 40, 0, 0);
        easterEgg.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                tapCount++;
                if (tapCount >= 7) {
                    secretButton.setVisibility(View.VISIBLE);
                    statusText.setText("🔓 Secret mode unlocked!");
                    tapCount = 0;
                }
            }
        });
        mainLayout.addView(easterEgg);
        
        setContentView(mainLayout);
    }
    
    private void testNativeHooks() {
        boolean init = initNative();
        String prop1 = getSystemProperty("ro.product.model");
        String prop2 = getSystemProperty("ro.build.version.release");
        String prop3 = getPropHook("ro.product.manufacturer");
        
        statusText.setText(
            "Init: " + init + "\n" +
            "Model: " + prop1 + "\n" +
            "Android: " + prop2 + "\n" +
            "Manufacturer: " + prop3
        );
    }
    
    private void showIdentity() {
        IdentityGenerator identity = new IdentityGenerator();
        String fakeId = identity.generateFakeIdentity();
        
        statusText.setText("🎭 Fake Identity:\n" + fakeId);
    }
    
    private void startBinderService() {
        try {
            BinderInterceptor interceptor = new BinderInterceptor();
            String result = interceptor.hookService("activity");
            statusText.setText("Binder Hook:\n" + result);
        } catch (Exception e) {
            statusText.setText("Binder Error: " + e.getMessage());
        }
    }
    
    private void launchSecretMode() {
        Intent intent = new Intent(this, SecretLauncherActivity.class);
        startActivity(intent);
    }
}
