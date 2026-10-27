package com.mihir.tvhome;

import android.accessibilityservice.AccessibilityService;
import android.content.Intent;
import android.view.KeyEvent;
import android.view.accessibility.AccessibilityEvent;

/**
 * Intercepts the Xiaomi remote's PatchWall button (BUTTON_2 / PROG_RED)
 * anywhere in the system and directly jumps to the connected HDMI input.
 */
public class KeyRemapService extends AccessibilityService {

    public static final String ACTION_LAUNCH_HDMI = "com.mihir.tvhome.ACTION_LAUNCH_HDMI";

    @Override
    protected boolean onKeyEvent(KeyEvent event) {
        if (event.getAction() == KeyEvent.ACTION_UP) {
            int code = event.getKeyCode();
            if (code == KeyEvent.KEYCODE_BUTTON_2 || code == KeyEvent.KEYCODE_PROG_RED) {
                Intent i = new Intent(this, MainActivity.class);
                i.setAction(ACTION_LAUNCH_HDMI);
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
                startActivity(i);
                return true;
            }
        }
        return super.onKeyEvent(event);
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) { }

    @Override
    public void onInterrupt() { }
}
