package com.termux.x11;

import android.content.Context;
import android.content.SharedPreferences;
import java.util.HashMap;

public class Prefs {
    public static class Pref<T> {
        private T val;
        public Pref(T v) { val = v; }
        public T get() { return val; }
        public void put(T v) { val = v; }
    }
    
    public static class DummyPreference {
        public Pref<String> asList() {
            return new Pref<>("none");
        }
    }
    
    public Pref<Boolean> showMouseHelper = new Pref<>(false);
    public Pref<String> touchMode = new Pref<>("1");
    public Pref<Boolean> enforceCharBasedInput = new Pref<>(false);
    public Pref<Boolean> keepScreenOn = new Pref<>(true);
    public Pref<Boolean> fullscreen = new Pref<>(false);
    public Pref<Boolean> enableSoftKeyboardModifiers = new Pref<>(false);
    public Pref<Boolean> stylusButtonContactModifierMode = new Pref<>(false);
    public Pref<Boolean> pauseKeyInterceptingWithEsc = new Pref<>(false);
    public Pref<String> transformCapturedPointer = new Pref<>("none");
    public Pref<Boolean> pointerCapture = new Pref<>(false);
    public Pref<Boolean> ignoreGamepadEvents = new Pref<>(false);
    public Pref<String> displayResolutionMode = new Pref<>("native");
    public Pref<Integer> displayScale = new Pref<>(100);
    public Pref<String> displayResolutionExact = new Pref<>("1080x1920");
    public Pref<String> displayResolutionCustom = new Pref<>("1080x1920");
    public Pref<Boolean> adjustResolution = new Pref<>(true);
    public Pref<Boolean> displayStretch = new Pref<>(true);
    public Pref<String> displayFilteringMode = new Pref<>("nearest");
    public Pref<Boolean> hardwareKbdScancodesWorkaround = new Pref<>(false);
    public Pref<Boolean> clipboardEnable = new Pref<>(true);
    
    public Pref<Boolean> tapToMove = new Pref<>(true);
    public Pref<Boolean> preferScancodes = new Pref<>(false);
    public Pref<Boolean> scaleTouchpad = new Pref<>(false);
    public Pref<Integer> capturedPointerSpeedFactor = new Pref<>(100);
    public Pref<Boolean> dexMetaKeyCapture = new Pref<>(false);
    public Pref<Boolean> stylusIsMouse = new Pref<>(false);
    
    public HashMap<String, DummyPreference> keys = new HashMap<>();

    public void load(Context context) {
        if (context == null) return;
        SharedPreferences sp = null;
        try {
            Context termuxContext = context.createPackageContext("com.termux.x11", Context.CONTEXT_IGNORE_SECURITY);
            sp = termuxContext.getSharedPreferences("com.termux.x11_preferences", Context.MODE_PRIVATE);
        } catch (Exception ignored) {}
        if (sp == null) {
            sp = context.getSharedPreferences("x11_preferences", Context.MODE_PRIVATE);
        }

        tapToMove.put(sp.getBoolean("tapToMove", true));
        touchMode.put(sp.getString("touchMode", "1"));
        stylusIsMouse.put(sp.getBoolean("stylusIsMouse", false));
        showMouseHelper.put(sp.getBoolean("showMouseHelper", false));
        pointerCapture.put(sp.getBoolean("pointerCapture", false));
        keepScreenOn.put(sp.getBoolean("keepScreenOn", true));
        displayResolutionMode.put(sp.getString("displayResolutionMode", "native"));
        displayScale.put(sp.getInt("displayScale", 100));
        displayFilteringMode.put(sp.getString("displayFilteringMode", "nearest"));
        displayStretch.put(sp.getBoolean("displayStretch", true));
        capturedPointerSpeedFactor.put(sp.getInt("capturedPointerSpeedFactor", 100));
    }

    public void save(Context context) {
        if (context == null) return;
        SharedPreferences sp = context.getSharedPreferences("x11_preferences", Context.MODE_PRIVATE);
        sp.edit()
            .putBoolean("tapToMove", tapToMove.get())
            .putString("touchMode", touchMode.get())
            .putBoolean("stylusIsMouse", stylusIsMouse.get())
            .putBoolean("showMouseHelper", showMouseHelper.get())
            .putBoolean("pointerCapture", pointerCapture.get())
            .putBoolean("keepScreenOn", keepScreenOn.get())
            .putString("displayResolutionMode", displayResolutionMode.get())
            .putInt("displayScale", displayScale.get())
            .putString("displayFilteringMode", displayFilteringMode.get())
            .putBoolean("displayStretch", displayStretch.get())
            .putInt("capturedPointerSpeedFactor", capturedPointerSpeedFactor.get())
            .apply();

        try {
            Context termuxContext = context.createPackageContext("com.termux.x11", Context.CONTEXT_IGNORE_SECURITY);
            SharedPreferences txSp = termuxContext.getSharedPreferences("com.termux.x11_preferences", Context.MODE_PRIVATE);
            txSp.edit()
                .putBoolean("tapToMove", tapToMove.get())
                .putString("touchMode", touchMode.get())
                .putBoolean("stylusIsMouse", stylusIsMouse.get())
                .putBoolean("showMouseHelper", showMouseHelper.get())
                .putBoolean("pointerCapture", pointerCapture.get())
                .putBoolean("keepScreenOn", keepScreenOn.get())
                .putString("displayResolutionMode", displayResolutionMode.get())
                .putInt("displayScale", displayScale.get())
                .putString("displayFilteringMode", displayFilteringMode.get())
                .putBoolean("displayStretch", displayStretch.get())
                .putInt("capturedPointerSpeedFactor", capturedPointerSpeedFactor.get())
                .apply();
        } catch (Exception ignored) {}
    }
}
