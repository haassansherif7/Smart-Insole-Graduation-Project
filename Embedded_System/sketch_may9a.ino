/* ESP32 Arduino: read 5x SHT31 via TCA9548A + 5x FSR ADC -> POST to Replit endpoint
   Mapping:
   SHT1 -> Temp1
   SHT2 -> BigF_T
   SHT3 -> Center_T
   SHT4 -> Side_T
   SHT5 -> Temp2

   FSR1 -> Pres1
   FSR2 -> Pres2
   FSR3 -> Center_P
   FSR4 -> Side_P
   FSR5 -> BigF_P
*/

#include <WiFi.h>
#include <HTTPClient.h>
#include <Wire.h>
#include "Adafruit_SHT31.h"
#include <WiFiClientSecure.h>

///// =========== CONFIG ========
const char* WIFI_SSID = "Bieber";
const char* WIFI_PASS = "123456789";

// <<< مهم: غيّر السطر ده لرابط Replit الخاص بيك (مع /ingest) >>>
const char* INGEST_URL = "https://ff187e73-034f-4ea9-9be5-8e6b3f6c1b7b-00-1dt7d1bz58mvb.janeway.replit.dev/ingest";

// ضع هنا نفس الـ device secret اللي حاططه في Replit secrets
const char* DEVICE_TOKEN = "myDevice-ABCD-1234";

#define TCA_ADDR 0x70  // default TCA9548A address
Adafruit_SHT31 sht = Adafruit_SHT31();

// ADC pins for FSRs (change if needed) - 1-based mapping in comments above
const int FSR_PINS[5] = {32, 33, 34, 35, 36}; // FSR1..FSR5

// helper: select TCA channel (0..7)
void tcaSelect(uint8_t channel) {
  if (channel > 7) return;
  Wire.beginTransmission(TCA_ADDR);
  Wire.write(1 << channel);
  Wire.endTransmission();
}

// read SHT on a TCA channel; returns true if read succeeded
bool readSHTonChannel(int ch, float &temp, float &hum) {
  tcaSelect(ch);
  delay(10);
  // initialize sensor on that channel (address 0x44)
  if (!sht.begin(0x44)) {
    return false;
  }
  delay(10);
  temp = sht.readTemperature();
  hum = sht.readHumidity();
  return true;
}

void setup() {
  Serial.begin(115200);
  delay(200);

  Wire.begin(); // default SDA=21, SCL=22 (change if board different)

  // Initialize ADC resolution
  analogReadResolution(12); // 0..4095

  // connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("Connecting to WiFi");
  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED) {
    delay(300);
    Serial.print(".");
    if (millis() - start > 30000) { // timeout 30s
      Serial.println("\nWiFi connect timeout - rebooting...");
      ESP.restart();
    }
  }
  Serial.println();
  Serial.print("WiFi connected. IP: ");
  Serial.println(WiFi.localIP());
}

void loop() {
  // --- Read 5 SHT31 sensors ---
  float temps[5];
  float hums[5];
  for (int i = 0; i < 5; ++i) {
    float t = -999.0, h = -999.0;
    bool ok = readSHTonChannel(i, t, h);
    if (!ok) {
      Serial.printf("Warning: no SHT found on TCA channel %d\n", i);
    }
    temps[i] = t;
    hums[i] = h;
    delay(30);
  }

  // --- Read 5 FSRs (raw ADC 0..4095) ---
  int pres[5];
  for (int i = 0; i < 5; ++i) {
    int v = analogRead(FSR_PINS[i]); // 0..4095 (12-bit)
    pres[i] = v;
    delay(5);
  }

  // --- Build JSON with the exact requested field names ---
  String json = "{";

  // device id
  json += "\"device_id\":\"esp32-001\",";

  // SHT mapping:
  json += "\"Temp1\":"  + String((int)round(temps[0]))  + ",";
  json += "\"BigF_T\":" + String((int)round(temps[1]))  + ",";
  json += "\"Center_T\":" + String((int)round(temps[2])) + ",";
  json += "\"Side_T\":" + String((int)round(temps[3]))  + ",";
  json += "\"Temp2\":"  + String((int)round(temps[4]))  + ",";

  // FSR mapping:
  json += "\"Pres1\":"  + String(pres[0]) + ",";
  json += "\"Pres2\":"  + String(pres[1]) + ",";
  json += "\"Center_P\":" + String(pres[2]) + ",";
  json += "\"Side_P\":"   + String(pres[3]) + ",";
  json += "\"BigF_P\":"  + String(pres[4]);

  json += "}";

  Serial.println("Prepared JSON:");
  Serial.println(json);

  // --- Send POST to Replit ingest endpoint ---
  if (WiFi.status() == WL_CONNECTED) {
    WiFiClientSecure *client = new WiFiClientSecure;
    client->setInsecure(); // للتجربة فقط — لاحقًا استعمل certificate pinning
    HTTPClient https;
    if (https.begin(*client, INGEST_URL)) {
      https.addHeader("Content-Type", "application/json");
      https.addHeader("X-DEVICE-TOKEN", DEVICE_TOKEN);
      int httpCode = https.POST(json);
      Serial.printf("POST code: %d\n", httpCode);
      String payload = https.getString();
      Serial.println("Response:");
      Serial.println(payload);
      https.end();
    } else {
      Serial.println("Failed to begin HTTPS");
    }
    delete client;
  } else {
    Serial.println("WiFi not connected");
  }

  // wait before next cycle
  delay(15000); // 15 seconds
}