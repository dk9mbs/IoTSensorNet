/*
 * 
 * https://arduino-esp8266.readthedocs.io/en/latest/esp8266wifi/station-class.html
*/


#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <PubSubClient.h>
#include <OneWire.h>
#include <FS.h>
#include <OneWire.h>
#include <DallasTemperature.h>


WiFiClient espClient;

const char* broadcastAddress="192.168.2.255";
long lastMsg = 0;
char msg[50];
int value = 0;


void setup() { 
  Serial.begin(115200);
  /*
   * mount the filesystem
   */
  SPIFFS.begin();
  
  if(!SPIFFS.exists("/ssid.cfg") || !SPIFFS.exists("/password.cfg") || !SPIFFS.exists("/mac.cfg") || !SPIFFS.exists("/mode.cfg") || !SPIFFS.exists("/sleeptime.cfg") ) {
    Serial.println("missing configfiles:");
    Serial.println("/ssid.cfg");
    Serial.println("/password.cfg");
    Serial.println("/mac.cfg");
    Serial.println("/mode.cfg");
    Serial.println("/sleeptime.cfg");
    
    while(1==1) {
      Serial.print("*");
      delay(5000);
    }
  }

  
  setup_wifi(readConfigValue("ssid").c_str(), readConfigValue("password").c_str(), readConfigValue("mac").c_str());

}


void loop() {
  
}

void setup_wifi(const char* ssid, const char* password, const char* newMacStr) {
  uint8_t mac[6];
  byte newMac[6];
  parseBytes(newMacStr, '-', newMac, 6, 16);

  ESP.eraseConfig();
  WiFi.setAutoConnect(true);
  WiFi.setAutoReconnect(true);

  wifi_set_macaddr(0, const_cast<uint8*>(newMac));
  Serial.println("mac address is set");

  delay(10);
  Serial.print("Connecting to ");
  Serial.println(ssid);
  WiFi.mode(WIFI_AP_STA);
  WiFi.softAP("iot.ki5hdh.de","tastatur");
  WiFi.softAPConfig(IPAddress(192,168,4,1), IPAddress(192,168,2,1), IPAddress(255, 255, 255, 0));
  WiFi.begin(ssid, password);


  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  WiFi.macAddress(mac);
  
  Serial.println("WiFi connected");
  Serial.print("IP address:");
  Serial.println(WiFi.localIP());
  Serial.printf("Mac address:%02x:%02x:%02x:%02x:%02x:%02x\n",mac[0],mac[1],mac[2],mac[3],mac[4],mac[5]);
  Serial.printf("Mac address:%s\n", WiFi.macAddress().c_str());
  Serial.print("Subnet mask:");
  Serial.println(WiFi.subnetMask());
  Serial.print("Gateway:");
  Serial.println(WiFi.gatewayIP());
  Serial.println("--- WiFi DIAG ---");
  WiFi.printDiag(Serial);

}


String readConfigValue(String name) {
  String result;
  File f = SPIFFS.open("/"+name+".cfg","r");
  result=f.readString();
  result.replace("\n", "");
  result.replace("\r", "");
  result.replace("\t", "");
  f.close();
  return result;
}

String deviceAddress2String(DeviceAddress deviceAddress){
  String addr="";
  for (uint8_t i = 0; i < 8; i++)
  {
    if(deviceAddress[i]<16) addr+="0";
    addr+=String(deviceAddress[i],HEX);
  }
  addr.toUpperCase();
  return addr;
}


void parseBytes(const char* str, char sep, byte* bytes, int maxBytes, int base) {
    for (int i = 0; i < maxBytes; i++) {
        bytes[i] = strtoul(str, NULL, base);  // Convert byte
        str = strchr(str, sep);               // Find next separator
        if (str == NULL || *str == '\0') {
            break;                            // No more separators, exit
        }
        str++;                                // Point to next character after separator
    }
}
