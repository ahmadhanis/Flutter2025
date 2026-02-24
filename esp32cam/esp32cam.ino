#include <WiFi.h>
#include "esp_camera.h"
#include <WebSocketsClient.h>

// ----------------------
// WIFI CONFIG
// ----------------------
const char* ssid = "myUUM_Guest";
const char* password = "";

// ----------------------
// WEBSOCKET SERVER
// ----------------------
WebSocketsClient wsClient;
const char* ws_host = "esp32cam-relay.onrender.com";
const int   ws_port = 443;   // wss
const char* ws_path = "/ws";

void startCamera();

// ======================================================
// SETUP
// ======================================================
void setup() {
  Serial.begin(115200);
  Serial.setDebugOutput(false);
  delay(2000);

  Serial.println("\nConnecting to WiFi.");

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(400);
  }

  Serial.println("\nWiFi connected");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  startCamera();

  // ----------------------
  // WebSocket setup
  // ----------------------
  wsClient.beginSSL(ws_host, ws_port, ws_path);
  wsClient.onEvent(wsEvent);
  wsClient.setReconnectInterval(5000);  // auto reconnect
  wsClient.enableHeartbeat(15000, 3000, 2); 

  Serial.println("Setup complete!");
}

// ======================================================
// CAMERA INIT
// ======================================================
void startCamera() {
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;

  // AI Thinker pins
  config.pin_d0 = 5;
  config.pin_d1 = 18;
  config.pin_d2 = 19;
  config.pin_d3 = 21;
  config.pin_d4 = 36;
  config.pin_d5 = 39;
  config.pin_d6 = 34;
  config.pin_d7 = 35;
  config.pin_xclk = 0;
  config.pin_pclk = 22;
  config.pin_vsync = 25;
  config.pin_href = 23;
  config.pin_sscb_sda = 26;
  config.pin_sscb_scl = 27;
  config.pin_pwdn = 32;
  config.pin_reset = -1;

  config.xclk_freq_hz = 20000000;
  config.pixel_format  = PIXFORMAT_JPEG;
  config.frame_size    = FRAMESIZE_QVGA;  // QVGA = fast & stable
  config.jpeg_quality  = 12;
  config.fb_count      = 1;

  // Start camera
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("\nCamera init failed! Error: 0x%x\n", err);
    delay(5000);
    ESP.restart();
  }

  Serial.println("Camera initialized!");
}

// ======================================================
// WEBSOCKET EVENTS
// ======================================================
void wsEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch (type) {
    case WStype_CONNECTED:
      Serial.println("[WSS] Connected to server!");
      break;

    case WStype_DISCONNECTED:
      Serial.println("[WSS] Disconnected. Reconnecting...");
      break;

    case WStype_ERROR:
      Serial.println("[WSS] ERROR!");
      break;

    case WStype_TEXT:
      Serial.print("[WSS MESSAGE] ");
      Serial.println((char*)payload);
      break;
  }
}

// ======================================================
// MAIN LOOP - Capture + Send Frames
// ======================================================
unsigned long lastFrame = 0;

void loop() {
  wsClient.loop();

  if (!wsClient.isConnected()) {
    return; // don't capture if not connected
  }

  // Limit FPS (optional)
  if (millis() - lastFrame < 120) return;
  lastFrame = millis();

  camera_fb_t * fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("[Camera] Failed to capture frame!");
    return;
  }

  // Debug frame size
  Serial.print("Sending frame: ");
  Serial.println(fb->len);

  // Send binary JPEG
  wsClient.sendBIN(fb->buf, fb->len);

  esp_camera_fb_return(fb);
}
