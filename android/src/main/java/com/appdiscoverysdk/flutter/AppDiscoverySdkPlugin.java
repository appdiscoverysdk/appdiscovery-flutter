package com.appdiscoverysdk.flutter;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.appdiscoverysdk.AppDiscovery;
import com.appdiscoverysdk.Offerwall;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import kotlin.Unit;

/**
 * Bridges Flutter calls to the AppDiscovery Android SDK.
 *
 * The offerwall host is a required setting: there is no default.
 */
public class AppDiscoverySdkPlugin
        implements FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware, EventChannel.StreamHandler {

    static final String METHOD_CHANNEL_NAME = "com.appdiscoverysdk.flutter/methods";
    static final String EVENT_CHANNEL_NAME = "com.appdiscoverysdk.flutter/events";

    private MethodChannel methodChannel;
    private EventChannel eventChannel;
    private EventChannel.EventSink eventSink;
    private Activity currentActivity;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    // Configuration remembered from initSDK / setUserId, used when a call omits a value.
    private String activeHost = "";
    private String activeTrackerHost = null;
    private String activeAppId = "";
    private String activeSdkKey = "";
    private String activePlayerId = "";

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel = new MethodChannel(binding.getBinaryMessenger(), METHOD_CHANNEL_NAME);
        methodChannel.setMethodCallHandler(this);
        eventChannel = new EventChannel(binding.getBinaryMessenger(), EVENT_CHANNEL_NAME);
        eventChannel.setStreamHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel.setMethodCallHandler(null);
        eventChannel.setStreamHandler(null);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "initSDK":
                activeHost = stringArg(call, "host");
                activeTrackerHost = nullableStringArg(call, "trackerHost");
                activeAppId = stringArg(call, "appId");
                activeSdkKey = stringArg(call, "sdkKey");
                activePlayerId = stringArg(call, "playerId");
                result.success(true);
                break;

            case "setUserId":
                activePlayerId = stringArg(call, "playerId");
                result.success(true);
                break;

            case "showOfferwall":
                showOfferwall(call, result);
                break;

            case "syncPendingRewards":
                syncPendingRewards(call, result);
                break;

            default:
                result.notImplemented();
        }
    }

    private void showOfferwall(MethodCall call, MethodChannel.Result result) {
        final Activity activity = currentActivity;
        if (activity == null) {
            result.error("NO_ACTIVITY", "Cannot show the offerwall without an active foreground Activity", null);
            return;
        }

        final String hostArg = stringArg(call, "host");
        final String host = firstNonEmpty(hostArg, activeHost);
        // The remembered tracker host belongs to the remembered host only.
        final String trackerHost = firstNonEmpty(nullableStringArg(call, "trackerHost"), hostArg.isEmpty() ? activeTrackerHost : null);
        final String app = firstNonEmpty(stringArg(call, "appId"), activeAppId);
        final String key = firstNonEmpty(stringArg(call, "sdkKey"), activeSdkKey);
        final String user = firstNonEmpty(stringArg(call, "playerId"), activePlayerId);

        if (app.isEmpty() || key.isEmpty()) {
            result.error("INVALID_CONFIG", "appId and sdkKey must be provided", null);
            return;
        }

        try {
            Offerwall offerwall = AppDiscovery.INSTANCE.create(host, app, key, user, trackerHost);

            offerwall.setOnReward(reward -> {
                final Map<String, Object> data = toMap(reward);
                mainHandler.post(() -> {
                    if (eventSink != null) {
                        Map<String, Object> event = new HashMap<>();
                        event.put("event", "onReward");
                        event.put("data", data);
                        eventSink.success(event);
                    }
                });
                return Unit.INSTANCE;
            });

            offerwall.setOnClose(() -> {
                mainHandler.post(() -> {
                    if (eventSink != null) {
                        Map<String, Object> event = new HashMap<>();
                        event.put("event", "onClose");
                        eventSink.success(event);
                    }
                });
                return Unit.INSTANCE;
            });

            offerwall.launch(activity);
            result.success(true);
        } catch (IllegalArgumentException e) {
            result.error("INVALID_HOST", e.getMessage(), null);
        } catch (Exception e) {
            result.error("LAUNCH_ERROR", e.getMessage(), null);
        }
    }

    private void syncPendingRewards(MethodCall call, MethodChannel.Result result) {
        final String hostArg = stringArg(call, "host");
        final String host = firstNonEmpty(hostArg, activeHost);
        // The remembered tracker host belongs to the remembered host only.
        final String trackerHost = firstNonEmpty(nullableStringArg(call, "trackerHost"), hostArg.isEmpty() ? activeTrackerHost : null);
        final String app = firstNonEmpty(stringArg(call, "appId"), activeAppId);
        final String key = firstNonEmpty(stringArg(call, "sdkKey"), activeSdkKey);
        final String user = firstNonEmpty(stringArg(call, "playerId"), activePlayerId);

        try {
            AppDiscovery.INSTANCE.syncPendingRewards(host, app, key, user, trackerHost, rewards -> {
                List<Map<String, Object>> list = new ArrayList<>();
                for (Map<String, ?> reward : rewards) {
                    list.add(toMap(reward));
                }
                result.success(list);
                return Unit.INSTANCE;
            });
        } catch (IllegalArgumentException e) {
            result.error("INVALID_HOST", e.getMessage(), null);
        } catch (Exception e) {
            result.error("SYNC_ERROR", e.getMessage(), null);
        }
    }

    // --- helpers ---------------------------------------------------------------

    @NonNull
    private static String stringArg(MethodCall call, String name) {
        String value = call.argument(name);
        return value == null ? "" : value.trim();
    }

    @Nullable
    private static String nullableStringArg(MethodCall call, String name) {
        String value = call.argument(name);
        return (value == null || value.trim().isEmpty()) ? null : value.trim();
    }

    private static String firstNonEmpty(@Nullable String preferred, String fallback) {
        return (preferred != null && !preferred.isEmpty()) ? preferred : fallback;
    }

    /** Reward payloads come from JSON; make every value encodable by the platform channel. */
    private static Map<String, Object> toMap(@Nullable Map<String, ?> source) {
        Map<String, Object> out = new HashMap<>();
        if (source == null) return out;
        for (Map.Entry<String, ?> entry : source.entrySet()) {
            out.put(entry.getKey(), toCodecValue(entry.getValue()));
        }
        return out;
    }

    @Nullable
    private static Object toCodecValue(@Nullable Object value) {
        if (value == null || value == JSONObject.NULL) return null;
        if (value instanceof Boolean || value instanceof Number || value instanceof String) return value;
        if (value instanceof JSONObject) {
            JSONObject json = (JSONObject) value;
            Map<String, Object> map = new HashMap<>();
            Iterator<String> keys = json.keys();
            while (keys.hasNext()) {
                String k = keys.next();
                map.put(k, toCodecValue(json.opt(k)));
            }
            return map;
        }
        if (value instanceof JSONArray) {
            JSONArray array = (JSONArray) value;
            List<Object> list = new ArrayList<>();
            for (int i = 0; i < array.length(); i++) {
                try {
                    list.add(toCodecValue(array.get(i)));
                } catch (JSONException e) {
                    list.add(null);
                }
            }
            return list;
        }
        if (value instanceof Map) {
            Map<String, Object> map = new HashMap<>();
            for (Object o : ((Map<?, ?>) value).entrySet()) {
                Map.Entry<?, ?> e = (Map.Entry<?, ?>) o;
                map.put(String.valueOf(e.getKey()), toCodecValue(e.getValue()));
            }
            return map;
        }
        if (value instanceof Iterable) {
            List<Object> list = new ArrayList<>();
            for (Object o : (Iterable<?>) value) list.add(toCodecValue(o));
            return list;
        }
        return value.toString();
    }

    // --- ActivityAware ----------------------------------------------------------

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        currentActivity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        currentActivity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        currentActivity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        currentActivity = null;
    }

    // --- EventChannel.StreamHandler ---------------------------------------------

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        eventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        eventSink = null;
    }
}
