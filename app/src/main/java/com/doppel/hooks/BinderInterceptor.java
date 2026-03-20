package com.doppel.hooks;

import android.os.IBinder;
import android.util.Log;
import java.lang.reflect.Method;

public class BinderInterceptor {
    
    private static final String TAG = "DoppelBinder";
    
    public String hookService(String serviceName) {
        try {
            Log.i(TAG, "Attempting to hook service: " + serviceName);
            
            // Use reflection to access ServiceManager
            Class<?> serviceManager = Class.forName("android.os.ServiceManager");
            Method getService = serviceManager.getMethod("getService", String.class);
            
            IBinder binder = (IBinder) getService.invoke(null, serviceName);
            
            if (binder == null) {
                return "Service " + serviceName + " not found";
            }
            
            return String.format(
                "Service: %s\nInterface: %s\nBinder: %s",
                serviceName,
                binder.getInterfaceDescriptor(),
                binder.toString()
            );
            
        } catch (ClassNotFoundException e) {
            Log.e(TAG, "ServiceManager class not found", e);
            return "Hook failed: ServiceManager not available";
        } catch (NoSuchMethodException e) {
            Log.e(TAG, "getService method not found", e);
            return "Hook failed: Method not found";
        } catch (Exception e) {
            Log.e(TAG, "Hook failed", e);
            return "Hook failed: " + e.getClass().getSimpleName();
        }
    }
}
