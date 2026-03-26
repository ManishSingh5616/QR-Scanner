package com.example.flutter_application_1

import android.content.Intent
import android.provider.Settings
import android.net.wifi.WifiNetworkSpecifier
import android.net.ConnectivityManager
import android.net.NetworkRequest
import android.net.NetworkCapabilities
import android.content.Context
import android.net.wifi.WifiNetworkSuggestion
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "wifi_connect"

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                if (call.method == "connectWifi") {
                    val ssid = call.argument<String>("ssid")
                    val password = call.argument<String>("password")

                    if (ssid != null && password != null) {
                        connectToWifi(ssid, password)
                        result.success("Connecting")
                    } else {
                        result.error("ERROR", "Invalid SSID or password", null)
                    }
                }

                else if (call.method == "openWifiSettings") {
                    val intent = Intent(Settings.ACTION_WIFI_SETTINGS)
                    startActivity(intent)
                    result.success("Opened Settings")
                }

                else {
                    result.notImplemented()
                }
            }
    }

    private fun connectToWifi(ssid: String, password: String) {
        val specifier = WifiNetworkSpecifier.Builder()
            .setSsid(ssid)
            .setWpa2Passphrase(password)
            .build()

        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .setNetworkSpecifier(specifier)
            .build()

        val connectivityManager =
            applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        connectivityManager.requestNetwork(request, object : ConnectivityManager.NetworkCallback() {})
    }
}