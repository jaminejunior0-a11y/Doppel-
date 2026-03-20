package com.doppel.identity;

import java.util.Random;
import java.util.UUID;

public class IdentityGenerator {
    
    private String[] manufacturers = {"Samsung", "Google", "OnePlus", "Xiaomi", "Huawei", "LG", "Motorola", "Sony"};
    private String[] models = {"Galaxy S21", "Pixel 6", "9 Pro", "Mi 11", "P40 Pro", "G8", "Edge", "Xperia 1"};
    private String[] androidVersions = {"10", "11", "12", "13", "14"};
    
    public String generateFakeIdentity() {
        Random rand = new Random();
        
        String manufacturer = manufacturers[rand.nextInt(manufacturers.length)];
        String model = models[rand.nextInt(models.length)];
        String version = androidVersions[rand.nextInt(androidVersions.length)];
        String deviceId = UUID.randomUUID().toString().substring(0, 8);
        
        return String.format(
            "Manufacturer: %s\nModel: %s %s\nAndroid: %s\nDevice ID: %s\nFingerprint: %s/%s/%s:%s",
            manufacturer,
            manufacturer,
            model,
            version,
            deviceId,
            manufacturer.toLowerCase(),
            model.toLowerCase().replace(" ", "_"),
            deviceId,
            version
        );
    }
    
    public String spoofBuildProps() {
        // This would hook into system properties
        return "ro.product.manufacturer=Samsung\nro.product.model=SM-G998B";
    }
}
