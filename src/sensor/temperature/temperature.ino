/*
 * 
 * https://arduino-esp8266.readthedocs.io/en/latest/esp8266wifi/station-class.html
 * https://gist.github.com/bbx10/5a2885a700f30af75fc5
 * https://github.com/esp8266/Arduino/blob/4897e0006b5b0123a2fa31f67b14a3fff65ce561/libraries/ESP8266WiFi/src/include/wl_definitions.h
 * https://github.com/adafruit/Adafruit_MQTT_Library/blob/master/examples/mqtt_esp8266/mqtt_esp8266.ino
 * ToDo:
 * Mac Address in setupFileSystem: : replace : with -
*/


#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <OneWire.h>
#include <FS.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <ESP8266WebServer.h>
#include <ESP8266HTTPClient.h>

#include "Adafruit_MQTT.h"
#include "Adafruit_MQTT_Client.h"


#define TEST_DEEPSLEEP true
#define ONEWIREBUSPIN 4
#define SETUPPIN 5

OneWire  ds(2); 
OneWire oneWire(ONEWIREBUSPIN);
DallasTemperature sensors(&oneWire);
WiFiUDP udp;
WiFiClient espClient;
ESP8266WebServer httpServer(80);

Adafruit_MQTT_Client mqtt(&espClient, "", 1883, "", "");


const char* broadcastAddress="192.168.2.255";
long lastMsg = 0;
char msg[50];
int value = 0;
int modeSleepTimeSec=60;
char packetBuffer[UDP_TX_PACKET_MAX_SIZE + 1];
boolean modeDeepSleep=false;
boolean runSetup=false;
long loopDelay=0;

HTTPClient http;

void setup() { 
  Serial.begin(115200);
  setupIo();
  setupFileSystem();

  if(digitalRead(SETUPPIN)==0) runSetup=true;


  
  Serial.print("Setup:");
  Serial.println(digitalRead(SETUPPIN));
  
  if(runSetup) {
    setupWifiAP();
    setupHttpAdmin();
  } else {
    String mode=readConfigValue("mode");
    mode.toUpperCase();
    if(mode=="DEEPSLEEP") {
      modeDeepSleep=true;
      modeSleepTimeSec=readConfigValue("sleeptime").toInt();
      Serial.print("Mode:");
      Serial.println("deepsleep");
      Serial.print("Sleep Time in sec.:");
      Serial.println(modeSleepTimeSec);
    } else {
      modeSleepTimeSec=readConfigValue("sleeptime").toInt();
      Serial.print("Mode:");
      Serial.println("default");
      Serial.print("Delay between 2 measures in sec.:");
      Serial.println(modeSleepTimeSec);
    }

    setupWifiSTA(readConfigValue("ssid").c_str(), readConfigValue("password").c_str(), readConfigValue("mac").c_str(), modeDeepSleep);
    sensors.begin();
  
    delay(500);
    unsigned int localPort=3333;
    udp.begin(localPort);
    delay(100);
    
  } 



}


void loop() {
  if(runSetup) {
    httpServer.handleClient(); 
  } else {
    MQTT_connect();

    long now = millis();
    if (now - loopDelay > modeSleepTimeSec*1000 || loopDelay==0) {

        temp();
        loopDelay = now;
    }


    if(modeDeepSleep) {
      Serial.println("good night...");
      WiFi.disconnect();
      ESP.deepSleep(modeSleepTimeSec*1000000);
      delay(2000);
    }
  }
}

// ############# HTTP REQUEST ################ //

String makeRequest(String path, String payload)
{
  // wait for WiFi connection
  if ((WiFi.status() == WL_CONNECTED)) {


    Serial.print("[HTTP] begin...\n");
    http.begin(espClient, "http://dk0ay.dk9mbs.de/mqtt.php"); 
    http.addHeader("Content-Type", "application/json");

    Serial.print("[HTTP] POST...\n");
    //int httpCode = http.POST("{\"hello\":\"world\"}");
    int httpCode = http.POST(payload);
    
    // httpCode will be negative on error
    if (httpCode > 0) {
      // HTTP header has been send and Server response header has been handled
      Serial.printf("[HTTP] POST... code: %d\n", httpCode);

      // file found at server
      if (httpCode == HTTP_CODE_OK) {
        const String& payload = http.getString();
        Serial.println("received payload:\n<<");
        Serial.println(payload);
        Serial.println(">>");
      }
    } else {
      Serial.printf("[HTTP] POST... failed, error: %s\n", http.errorToString(httpCode).c_str());
    }

    http.end();
  }

}

// ###################################### //

void MQTT_connect() {
  int8_t ret;

  // Stop if already connected.
  if (mqtt.connected()) {
    return;
  }

  String user=readConfigValue("brokeruser");
  String pwd=readConfigValue("brokerpwd");
  String staticBroker=readConfigValue("staticbrokeraddr");
  int attempt=0;

  String mqttBroker;
  int mqttPort;
  if(staticBroker=="") {
    String clientInfo=String(sendConfigRequestandWaitForResponse("WHOISMQTTBROKER"));
    Serial.print("Clientinfo from udp client service:");
    Serial.println(clientInfo);
    String udpTopic=split(clientInfo,';',0);
    mqttBroker=split(clientInfo,';',1);
    mqttPort=split(clientInfo,';',2).toInt();
  } else {
    Serial.println("use static mqtt broker address!");
    mqttBroker=staticBroker;
    mqttPort=readConfigValue("staticbrokerport").toInt();
  }


  Serial.print("MQTT Boker:");
  Serial.println(mqttBroker);
  Serial.print("MQTT Port:");
  Serial.println(mqttPort);
  mqtt=Adafruit_MQTT_Client(&espClient, mqttBroker.c_str(), mqttPort, user.c_str(), pwd.c_str());

  // end dk9mbs
  
  Serial.print("Connecting to MQTT... ");

  uint8_t retries = 3;
  while ((ret = mqtt.connect()) != 0) { // connect will return 0 for connected
       Serial.println(mqtt.connectErrorString(ret));
       Serial.println("Retrying MQTT connection in 5 seconds...");
       mqtt.disconnect();
       delay(5000);  // wait 5 seconds
       retries--;
       if (retries == 0) {
         // basically die and wait for WDT to reset me
         while (1);
       }
  }
  Serial.println("MQTT Connected!");
}
/*
void reconnect(const char* clientName, PubSubClient client, boolean modeDeepSleep) {
  
  if(client.connected()) return;
  
  Serial.print("Wifi status:");
  Serial.println(WiFi.status());
  
  if(WiFi.status()!=WL_CONNECTED) {
    Serial.println("Wifi not connected!");
    setupWifiSTA(readConfigValue("ssid").c_str(), readConfigValue("password").c_str(), readConfigValue("mac").c_str(), modeDeepSleep);
  }

  String user=readConfigValue("brokeruser");
  String pwd=readConfigValue("brokerpwd");
  String staticBroker=readConfigValue("staticbrokeraddr");
  int attempt=0;
  
  while (!client.connected()) {
    //
    
    String mqttBroker;
    int mqttPort;
    if(staticBroker=="") {
      String clientInfo=String(sendConfigRequestandWaitForResponse("WHOISMQTTBROKER"));
      Serial.print("Clientinfo from udp client service:");
      Serial.println(clientInfo);
      String udpTopic=split(clientInfo,';',0);
      mqttBroker=split(clientInfo,';',1);
      mqttPort=split(clientInfo,';',2).toInt();
    } else {
      Serial.println("use static mqtt broker address!");
      mqttBroker=staticBroker;
      mqttPort=readConfigValue("staticbrokerport").toInt();
    }

  
    Serial.print("MQTT Boker:");
    Serial.println(mqttBroker);
    Serial.print("MQTT Port:");
    Serial.println(mqttPort);

    client.setServer(mqttBroker.c_str(), mqttPort);
    client.setCallback(callback);
    
    
    Serial.print("Attempting MQTT connection...");
    String clientId = "KI5HDH-";
    clientId += String(random(0xffff), HEX);
    if (client.connect(clientId.c_str(), user.c_str(),pwd.c_str())) {
      Serial.println("connected");
      client.publish("ki5hdh/client", (char*)clientId.c_str());
      client.subscribe("event");
      //client.loop();
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      // Wait 5 seconds before retrying
      delay(5000);
      attempt++;
      if(attempt==3) return;
    }
  }
}
*/

// http server
void setupHttpAdmin() {
  httpServer.on("/",handleHttpRoot);
  httpServer.onNotFound(handleHttp404);
  httpServer.begin();
}

void handleHttpRoot() {
    if(httpServer.hasArg("CMD")) {
      Serial.println(httpServer.arg("CMD"));
      handleSubmit();
    }
    
    String html =
    "<!DOCTYPE HTML>"
    "<html>"
    "<head>"
    "<meta name = \"viewport\" content = \"width = device-width, initial-scale = 1.0, maximum-scale = 1.0, user-scalable=0\">"
    "<title>DK9MBS/KI5HDH IoT Sensor</title>"
    "<style>"
    "\"body { background-color: #808080; font-family: Arial, Helvetica, Sans-Serif; Color: #000000; }\""
    "</style>"
    "</head>"
    "<body>"
    "<h1>Setup shell by dk9mbs</h1>"
    "<FORM action=\"/\" method=\"post\">"
    "<P>Wlan:"
    "<INPUT type=\"hidden\" name=\"CMD\" value=\"SAVE\"><BR>"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>ssid</div><INPUT style=\"width:99%;\" type=\"text\" name=\"SSID\" value=\""+ readConfigValue("ssid") +"\"></div>"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>Password</div><INPUT style=\"width:99%;\" type=\"text\" name=\"PASSWORD\" value=\""+ readConfigValue("password") +"\"></div>"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>MAC</div><INPUT style=\"width:99%;\" type=\"text\" name=\"MAC\" value=\""+ readConfigValue("mac") +"\"></div>"
    "</P>"
    "<P>System:"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>Mode</div><INPUT style=\"width:99%;\" type=\"text\" name=\"MODE\" value=\""+ readConfigValue("mode") +"\"></div>"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>Sleeptime</div><INPUT style=\"width:99%;\" type=\"text\" name=\"SLEEPTIME\" value=\""+ readConfigValue("sleeptime") +"\"></div>"
    "</P>"
    "<P>Admin portal"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>Admin Password</div><INPUT style=\"width:99%;\" type=\"text\" name=\"ADMINPWD\" value=\""+ readConfigValue("adminpwd") +"\"></div>"
    "</P>"
    "</P>"
    "<P>MQTT Broker"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>Static mqtt broker address (if empty then dynamic)</div><INPUT style=\"width:99%;\" type=\"text\" name=\"STATICBROKERADDR\" value=\""+ readConfigValue("staticbrokeraddr") +"\"></div>"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>Static mqtt broker port</div><INPUT style=\"width:99%;\" type=\"text\" name=\"STATICBROKERPORT\" value=\""+ readConfigValue("staticbrokerport") +"\"></div>"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>Username</div><INPUT style=\"width:99%;\" type=\"text\" name=\"BROKERUSER\" value=\""+ readConfigValue("brokeruser") +"\"></div>"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>Password</div><INPUT style=\"width:99%;\" type=\"text\" name=\"BROKERPWD\" value=\""+ readConfigValue("brokerpwd") +"\"></div>"
    "</P>"
    "<div><INPUT type=\"submit\" value=\"Send\"> <INPUT type=\"reset\"></div>"
    "</FORM>"
    "</body>"
    "</html>";
    httpServer.send(200, "text/html", html); 
}

void handleSubmit() {
  saveConfigValue("mode", httpServer.arg("MODE"));
  saveConfigValue("mac", httpServer.arg("MAC"));
  saveConfigValue("ssid", httpServer.arg("SSID"));
  saveConfigValue("password", httpServer.arg("PASSWORD"));
  saveConfigValue("sleeptime", httpServer.arg("SLEEPTIME"));
  saveConfigValue("adminpwd", httpServer.arg("ADMINPWD"));
  saveConfigValue("staticbrokeraddr", httpServer.arg("STATICBROKERADDR"));
  saveConfigValue("staticbrokerport", httpServer.arg("STATICBROKERPORT"));
  saveConfigValue("brokeruser", httpServer.arg("BROKERUSER"));
  saveConfigValue("brokerpwd", httpServer.arg("BROKERPWD"));
}

void handleHttp404() {
    httpServer.send(404, "text/plain", "404: Not found"); 
}

// mqtt
void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");
  for (int i = 0; i < length; i++) {
    Serial.print((char)payload[i]);
  }
  Serial.println();
  
}

void setupIo() {
  pinMode(SETUPPIN,INPUT);
}

void setupFileSystem() {
  if(!SPIFFS.begin()) {
    SPIFFS.format();
    SPIFFS.begin(); 
  }

  
  if(!SPIFFS.exists(getConfigFilename("mac"))) {
    String mac=WiFi.macAddress();
    mac.replace(":","-");
    saveConfigValue("mac", mac);
  }
  if(!SPIFFS.exists(getConfigFilename("ssid"))) saveConfigValue("ssid", "wlan-ssid");
  if(!SPIFFS.exists(getConfigFilename("password"))) saveConfigValue("password", "wlan-password");
  if(!SPIFFS.exists(getConfigFilename("mode"))) saveConfigValue("mode", "deepsleep");
  if(!SPIFFS.exists(getConfigFilename("sleeptime"))) saveConfigValue("sleeptime", "60");
  if(!SPIFFS.exists(getConfigFilename("adminpwd"))) saveConfigValue("adminpwd", "123456789ff");

  if(!SPIFFS.exists(getConfigFilename("staticbrokeraddr"))) saveConfigValue("staticbrokeraddr", "");
  if(!SPIFFS.exists(getConfigFilename("staticbrokerport"))) saveConfigValue("staticbrokerport", "1883");

  if(!SPIFFS.exists(getConfigFilename("brokeruser"))) saveConfigValue("brokeruser", "username");
  if(!SPIFFS.exists(getConfigFilename("brokerpwd"))) saveConfigValue("brokerpwd", "password");

}

void setupWifiAP(){
  Serial.println("Setup shell is starting ...");
  String pwd=readConfigValue("adminpwd");
  Serial.print("Password for AP:");
  Serial.println(pwd);
  
  WiFi.mode(WIFI_AP);
  WiFi.softAP("sensor.iot.dk9mbs.de", pwd);

  Serial.println("AP started");

}

void setupWifiSTA(const char* ssid, const char* password, const char* newMacStr, boolean modeDeepSleep) {
  uint8_t mac[6];
  byte newMac[6];
  parseBytes(newMacStr, '-', newMac, 6, 16);

  if(modeDeepSleep) {
    ESP.eraseConfig();
    //WiFi.setAutoConnect(true);
    WiFi.setAutoReconnect(true);
  } else {
    ESP.eraseConfig();//ein
    //WiFi.setAutoConnect(true);
    WiFi.setAutoReconnect(true);
  }
  
  wifi_set_macaddr(0, const_cast<uint8*>(newMac));
  Serial.println("mac address is set");

  delay(10);
  Serial.print("Connecting to ");
  Serial.println(ssid);
  WiFi.mode(WIFI_STA);
  Serial.print("Password:");
  Serial.println("***********");
  
  WiFi.begin(ssid, password);
  
  Serial.println("after WiFi.begin():");
  
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

void temp() {
  Serial.println("reading the sensors...");

  sensors.requestTemperatures();
  delay(500);
   
  int numberOfSensors=sensors.getDS18Count();
  float temperatureC;
  DeviceAddress mac;
  String address="";
  char temperaturenow [15];

  for(int x=0;x<numberOfSensors;x++){
    sensors.getAddress(mac, x);
    address=deviceAddress2String(mac);
    temperatureC = sensors.getTempCByIndex(x);
    Serial.print(address+": ");
    Serial.print(temperatureC);
    Serial.print("ºC : sending ... ");

    dtostrf(temperatureC,7, 3, temperaturenow);  //// convert float to char
    String payload = "{\"temp\":"+String(temperatureC)+", \"address\":\""+String(address)+"\"}";
    //client.publish("temp/sensor", (char*)payload.c_str());
    //makeRequest("/sensor/test", payload);

    Adafruit_MQTT_Publish sensorTopic = Adafruit_MQTT_Publish(&mqtt, "temp/sensor");
    if (! sensorTopic.publish(payload.c_str())) {
      Serial.println(F("Failed"));
    } else {
      Serial.println(F("OK!"));
    }

  }

}

void saveConfigValue(String name, String value) {
  File f =SPIFFS.open("/"+name+".cfg","w");
  f.print(value.c_str());
  f.close();
  Serial.print("Saved config value:");
  Serial.print(name+" -> ");
  Serial.println(readConfigValue(name));
}

String readConfigValue(String name) {
  String result="";
  String fileName="/"+name+".cfg";
  
  if(SPIFFS.exists(fileName)) {
    File f = SPIFFS.open(fileName, "r");
    result=f.readString();
    result.replace("\n", "");
    result.replace("\r", "");
    result.replace("\t", "");
    f.close();
  }

  return result;
}

String getConfigFilename(String name) {
  return "/"+name+".cfg";
}

void sendUdp(const char* msg, unsigned int port) {
  Serial.print("Sending udp:");
  Serial.println(msg);
  const char* broadcast=broadcastAddress;
  int beginResult;
  int endResult;
  beginResult=udp.beginPacket(broadcast, port);
  if(!beginResult) Serial.println("Error begin package!!!");
  udp.write(msg);
  endResult=udp.endPacket();
  if(!endResult) Serial.println("Error end package!!!");
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



String sendConfigRequestandWaitForResponse(String request) {
  int packetSize=0;
  unsigned int port=1200;
  int ttl=10;
  int timeout=ttl;

  sendUdp(request.c_str(), port);

  while(!packetSize) {
    packetSize = udp.parsePacket();
    Serial.print(".");
    delay(500);
    timeout--;
    if (timeout==0) {
      Serial.println("timeout arrived ... try to send new request ...");
      timeout=ttl;
      sendUdp(request.c_str(), port);
    }

  }

  int n = udp.read(packetBuffer, UDP_TX_PACKET_MAX_SIZE);
  packetBuffer[n] = 0;
  return String(packetBuffer);

}


String split(String s, char parser, int index) {
  String rs="";
  int parserIndex = index;
  int parserCnt=0;
  int rFromIndex=0, rToIndex=-1;
  while (index >= parserCnt) {
    rFromIndex = rToIndex+1;
    rToIndex = s.indexOf(parser,rFromIndex);
    if (index == parserCnt) {
      if (rToIndex == 0 || rToIndex == -1) return "";
      return s.substring(rFromIndex,rToIndex);
    } else parserCnt++;
  }
  return rs;
}
