
/*
 * 
 * https://arduino-esp8266.readthedocs.io/en/latest/esp8266wifi/station-class.html
 * https://gist.github.com/bbx10/5a2885a700f30af75fc5
 * https://github.com/esp8266/Arduino/blob/4897e0006b5b0123a2fa31f67b14a3fff65ce561/libraries/ESP8266WiFi/src/include/wl_definitions.h
 * https://github.com/adafruit/Adafruit_MQTT_Library/blob/master/examples/mqtt_esp8266/mqtt_esp8266.ino
 * 
 * https://github.com/lucasmaziero/LiquidCrystal_I2C
 * 
 * ToDo:
 * Mac Address in setupFileSystem: : replace : with -
*/

#define ENABLE_ONEWIRE true
#define ENABLE_DHT true
#define ENABLE_LIGHTNESS true
#define ENABLE_RAINFALL false
#define ENABLE_DISPLAY true

#ifdef ESP32
#pragma message(THIS EXAMPLE IS FOR ESP8266 ONLY!)
#error Select ESP8266 board.
#endif

#include "dk9mbs_tools.h"
#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <FS.h>

#if ENABLE_ONEWIRE
#include <OneWire.h>
#include <DallasTemperature.h>
#endif

#include <ESP8266WebServer.h>
#include <ESP8266HTTPClient.h>

#if ENABLE_DISPLAY
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#endif

#include "Adafruit_MQTT.h"
#include "Adafruit_MQTT_Client.h"


#define ONEWIREBUSPIN 4
#define SETUPPIN 5 
#define LIGHTNESS_IN_PIN A0
#define DHT_PIN 14
#define RAINFALL_PIN 13
#define DISPLAY_SCL 0 
#define DISPLAY_SDA 2 

#define DHT_TYPE DHT11
#define MQTT_PUB_TOPIC "temp/sensor"
#define PRE_TASK_MSSEC 5000
#define POST_TASK_MSSEC 500
#define DEBOUNCE_TIME_MS 20 // Entprellzeit digital in

#if ENABLE_ONEWIRE
OneWire  ds(2); 
OneWire oneWire(ONEWIREBUSPIN);
DallasTemperature sensors(&oneWire);
#endif

#if ENABLE_DISPLAY
LiquidCrystal_I2C lcd(0x27, 16, 2);
#endif

WiFiUDP udp;
WiFiClient espClient;
ESP8266WebServer httpServer(80);

Adafruit_MQTT_Client mqtt(&espClient, "", 1883, "", "");
Adafruit_MQTT_Publish sensorTopic = Adafruit_MQTT_Publish(&mqtt, MQTT_PUB_TOPIC, MQTT_QOS_0);
//Adafruit_MQTT_Subscribe displayChanel = Adafruit_MQTT_Subscribe(&mqtt, "node/test", MQTT_QOS_0);

#if ENABLE_DHT
#include "DHT.h"
DHT dht (DHT_PIN, DHT_TYPE);
#endif

#if ENABLE_RAINFALL
//Niederschlag mit Wippe gezaehlt
int rainfallCount=0;
int lastrainfallSignal=0; 
#endif

const char* broadcastAddress="192.168.2.255";
long lastMsg = 0;
char msg[50];
int value = 0;
int modeSleepTimeSec=60;
char packetBuffer[UDP_TX_PACKET_MAX_SIZE + 1];
boolean modeDeepSleep=false;
boolean runSetup=false;
long loopDelay=0;

int state=0; // Status from Statemachine

HTTPClient http;

void setup() { 
  Serial.begin(115200);

#if ENABLE_DISPLAY
  lcd.begin(DISPLAY_SDA, DISPLAY_SCL);
  lcd.setCursor(0, 0); // Spalte, Zeile
  printLcd(lcd, 0,1, "booting ...",1);
  delay (1000);
#endif

  setupIo();
  setupFileSystem();


  if(digitalRead(SETUPPIN)==0) runSetup=true;
  
  Serial.print("Setup:");
  Serial.println(digitalRead(SETUPPIN));
  Serial.print("adminpwd: ");
  Serial.println(readConfigValue("adminpwd"));
  
  if(runSetup) {
#if ENABLE_DISPLAY
    printLcd(lcd, 0,1, "enter setup ...",1);
#endif
    setupWifiAP();
    setupHttpAdmin();
  } else {
#if ENABLE_DISPLAY
    printLcd(lcd, 0,1, "setup hw ...",1);
#endif
    
    setupHttpAdmin();
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
    
#if ENABLE_ONEWIRE    
    sensors.begin();
#endif

#if ENABLE_DHT
    dht.begin(); 
#endif

#if ENABLE_RAINFALL
    attachInterrupt(digitalPinToInterrupt(RAINFALL_PIN), rainfallIsr, FALLING);
#endif

    delay(500);
    unsigned int localPort=3333;
    udp.begin(localPort);
    delay(100);

    //displayChanel.setCallback(mqttDisplayCallback);
    //mqtt.subscribe(&displayChanel);
  } // setup 
}

void loop() {
    httpServer.handleClient(); 

    mqttConnect();
    //mqtt.processPackets(10000);
    // Statemachine
    long now = millis();

    // Pre Process Tasks
    if(  (now - loopDelay > (modeSleepTimeSec*1000)-PRE_TASK_MSSEC  || loopDelay==0) && state==0  ) {
      Serial.println ("Executing pre tasks...");

#if ENABLE_ONEWIRE  
      sensors.requestTemperatures();
#endif
      state=1;
    }

    
    // Prcess Tasks
    if (  (now - loopDelay > modeSleepTimeSec*1000 || loopDelay==0) && state==1   ) {
      Serial.println ("Executing tasks...");
      String address;
      float value;
  

#if ENABLE_ONEWIRE
      readOneWireTempMultible();
#endif

#if ENABLE_DHT
      String addressHum;
      String addressTemp;
      float valueHum;
      float valueTemp;
      
      mqtt.disconnect();
      readDhtHum(dht, addressHum, valueHum);
      readDhtTemp(dht,addressTemp, valueTemp);
      mqttConnect();
  
      publishMqttSensorPayload(sensorTopic, addressHum, valueHum);
      publishMqttSensorPayload(sensorTopic, addressTemp, valueTemp);

#if ENABLE_DISPLAY
      printLcd(lcd, 0,0, "T:"+String(valueTemp)+"C H:"+String(valueHum)+"%", 1);
      printLcd(lcd, 0,1, "L:"+String(100)+"Lux", 0);
#endif

#endif

#if ENABLE_LIGHTNESS
      readLightness(address, value);
      publishMqttSensorPayload(sensorTopic, address, value);
#endif

#if ENABLE_RAINFALL
      readRainfall(address, value);
      publishMqttSensorPayload(sensorTopic, address, value);
#endif

      state=2;
    } // Process Task


    // Postprocess
    if(  (now - loopDelay > (modeSleepTimeSec*1000)+POST_TASK_MSSEC  || loopDelay==0) && state==2  ) {
      Serial.println ("Executing post tasks...");
      loopDelay = now;
      state=0;
    }
    //
    // End Statemachine
    //
    
    if(modeDeepSleep) {
      Serial.println("good night...");
      WiFi.disconnect();
      ESP.deepSleep(modeSleepTimeSec*1000000);
      delay(2000);
    }
} // function


void mqttDisplayCallback(char *data, uint16_t len) {
  Serial.print("Hey we're in a onoff callback, the button value is: ");
  Serial.println(data);
}


#if ENABLE_DISPLAY
void printLcd(LiquidCrystal_I2C& lcdDisplay,int column, int row, String text, int clear) {
  if(clear==1) lcdDisplay.clear();
  
  lcdDisplay.setCursor(column, row); // Spalte, Zeile
  lcdDisplay.print(text);
}
#endif

#if ENABLE_RAINFALL
void rainfallIsr() {
  int now=millis();
  if(now-lastrainfallSignal < DEBOUNCE_TIME_MS) return;
  
  rainfallCount++;
  lastrainfallSignal=millis();
}

void readRainfall(String& address, float& value) {
  Serial.println("reading the Rainfall sensor");
  address=createIoTDeviceAddress("rainfall");
  value=rainfallCount;

}
#endif

void publishMqttSensorPayload(Adafruit_MQTT_Publish& topic, String address, float value) {
  //strcpy(topic, readConfigValue("pubtopic").c_str());
  //Serial.print("Pubtopic: ");
  //Serial.println(topic);
  //Adafruit_MQTT_Publish sensorTopic = Adafruit_MQTT_Publish(&mqtt, topic);

  String payload="";
  payload = "{\"value\":"+String(value)+", \"address\":\""+address+"\"}";
  //sensorTopic.publish(payload.c_str());
  topic.publish(payload.c_str());
}

String createIoTDeviceAddress(String postfix) {
  String address=String(readConfigValue("mac")+"."+postfix);
  address.replace("-","");
  return address;  
}


#if ENABLE_DHT
void readDhtHum(DHT& dht, String& address, float& humidity) {
  Serial.println("reading the DHT sensor");
  address=createIoTDeviceAddress("hum");
  humidity = dht.readHumidity();
  /*
  Serial.print(dht.getStatusString());
  Serial.print(humidity, 1);
  Serial.print(temperature, 1);
  Serial.print(dht.computeHeatIndex(temperature, humidity, false), 1);
  Serial.println(dht.computeHeatIndex(dht.toFahrenheit(temperature), humidity, true), 1);
  */
  Serial.print("Humidity:");
  Serial.print(humidity);
  Serial.println("%");

}

void readDhtTemp(DHT& dht, String& address, float& temperature) {
  Serial.println("reading the DHT sensor");
  address=createIoTDeviceAddress("tempc");
  temperature = dht.readTemperature();

  Serial.print("Temperature:");
  Serial.print(temperature);
  Serial.println("°C");
  
}

#endif

#if ENABLE_LIGHTNESS
void readLightness(String& address, float& lux) {
  Serial.println("reading the lightness sensor");
  address=createIoTDeviceAddress("lightness");
  int sensorValue = analogRead(LIGHTNESS_IN_PIN);
  float voltage= sensorValue * (1.0 / 1023.0);
  lux=voltage*1333;
  Serial.print("Lightnessvalue:");
  Serial.print(voltage);
  Serial.println("mV");  
}
#endif

#if ENABLE_ONEWIRE
void readOneWireTempMultible() {
  Serial.println("reading the onewire sensors...");

  //sensors.requestTemperatures();
  //delay(500);
   
  //int numberOfSensors=sensors.getDS18Count();
  int numberOfSensors=sensors.getDeviceCount();
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

    publishMqttSensorPayload(sensorTopic, address,temperatureC); 
    /*
    payload = "{\"temp\":"+String(temperatureC)+", \"address\":\""+String(address)+"\"}";

    if (! sensorTopic.publish(payload.c_str())) {
      Serial.println(F("Failed"));
    } else {
      Serial.println(F("OK!"));
    }
    */
  }
}
#endif

void mqttConnect() {
  int8_t ret;

  if (mqtt.connected()) {
    return;
  }

  String user=readConfigValue("brokeruser");
  String pwd=readConfigValue("brokerpwd");
  String staticBroker=readConfigValue("staticbrokeraddr");
  int attempt=0;

  String mqttBroker;
  int mqttPort;
  String clientId=readConfigValue("hostname");
  
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
  Serial.print("MQTT ClientID:");
  Serial.println(clientId);
  
  mqtt=Adafruit_MQTT_Client(&espClient, mqttBroker.c_str(), mqttPort,clientId.c_str(), user.c_str(), pwd.c_str());

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

// http server
void setupHttpAdmin() {
  httpServer.on("/",handleHttpSetup);
  httpServer.on("/api",handleHttpApi);
  httpServer.onNotFound(handleHttp404);
  httpServer.begin();
}

void handleHttpApi() {
  httpServer.send(200, "text/html", "api"); 
}
void handleHttpSetup() {
    String pwd = readConfigValue("adminpwd");
    if (!httpServer.authenticate("admin", pwd.c_str())) {
      return httpServer.requestAuthentication();
    }
      
    if(httpServer.hasArg("CMD")) {
      Serial.println(httpServer.arg("CMD"));
      handleSubmit();
    }

    if(httpServer.hasArg("FORMATFS")) {
      Serial.println("Format FS");
      handleFormat();
    }
    if(httpServer.hasArg("RESET")) {
      Serial.println("Reset ...");
      handleReset();
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
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>MAC (A4-CF-12-DF-69-00)</div><INPUT style=\"width:99%;\" type=\"text\" name=\"MAC\" value=\""+ readConfigValue("mac") +"\"></div>"
    "</P>"
    "<P>Network:"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>Hostname</div><INPUT style=\"width:99%;\" type=\"text\" name=\"HOSTNAME\" value=\""+ readConfigValue("hostname") +"\"></div>"
    "</P>"
    "<P>System:"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>Mode</div><INPUT style=\"width:99%;\" type=\"text\" name=\"MODE\" value=\""+ readConfigValue("mode") +"\"></div>"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>Sleeptime (sec)</div><INPUT style=\"width:99%;\" type=\"text\" name=\"SLEEPTIME\" value=\""+ readConfigValue("sleeptime") +"\"></div>"
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
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>Publish topic</div><INPUT disabled maxlength=\"50\" style=\"width:99%;\" type=\"text\" name=\"PUBTOPIC\" value=\""+ MQTT_PUB_TOPIC +"\"></div>"
    "</P>"
    "<div>"
    "<INPUT type=\"submit\" value=\"Save\">"
    "<INPUT type=\"submit\" name=\"RESET\" value=\"Save and Reset\">"
    "<INPUT type=\"submit\" name=\"FORMATFS\" value=\"!!! Format fs !!!\">"
    "</div>"
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
  saveConfigValue("hostname", httpServer.arg("HOSTNAME"));
  saveConfigValue("pubtopic", httpServer.arg("PUBTOPIC"));
}

void handleReset() {
  httpServer.send(200, "text/plain", "restart ..."); 
  ESP.restart();
}

void handleFormat() {
  Serial.print("Format fs ... ");
  SPIFFS.format();
  setupFileSystem();
  Serial.println("ready");
}

void handleHttp404() {
  httpServer.send(404, "text/plain", "404: Not found"); 
}

void setupIo() {
  ESP.eraseConfig();
  WiFi.setAutoConnect(false);
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
  if(!SPIFFS.exists(getConfigFilename("hostname"))) saveConfigValue("hostname", "node");
  if(!SPIFFS.exists(getConfigFilename("pubtopic"))) saveConfigValue("pubtopic", "temp/sensor");
}

void setupWifiAP(){
  Serial.println("Setup shell is starting ...");
  String pwd=readConfigValue("adminpwd");

  if(pwd==""){
    Serial.println("Use default password!");
    pwd="0000";
  }
  
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

  WiFi.setAutoReconnect(true);

  if(newMacStr != "") {
    wifi_set_macaddr(0, const_cast<uint8*>(newMac));
    Serial.println("mac address is set");
  }
  
  wifi_station_set_hostname(readConfigValue("hostname").c_str());
  Serial.print("Hostname ist set: ");
  Serial.println(readConfigValue("hostname"));
  
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
  //WiFi.printDiag(Serial);

}




void sendUdp(const char* msg, unsigned int port,const char* broadcast, WiFiUDP udp) {
  Serial.print("Sending udp:");
  Serial.println(msg);
  //const char* broadcast=broadcastAddress;
  int beginResult;
  int endResult;
  beginResult=udp.beginPacket(broadcast, port);
  if(!beginResult) Serial.println("Error begin package!!!");
  udp.write(msg);
  endResult=udp.endPacket();
  if(!endResult) Serial.println("Error end package!!!");
}




String sendConfigRequestandWaitForResponse(String request) {
  int packetSize=0;
  unsigned int port=1200;
  int ttl=10;
  int timeout=ttl;

  sendUdp(request.c_str(), port, broadcastAddress, udp);

  while(!packetSize) {
    packetSize = udp.parsePacket();
    Serial.print(".");
    delay(500);
    timeout--;
    if (timeout==0) {
      Serial.println("timeout arrived ... try to send new request ...");
      timeout=ttl;
      sendUdp(request.c_str(), port, broadcastAddress, udp);
    }

  }

  int n = udp.read(packetBuffer, UDP_TX_PACKET_MAX_SIZE);
  packetBuffer[n] = 0;
  return String(packetBuffer);

}
