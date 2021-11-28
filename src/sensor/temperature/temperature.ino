
/*
 * 
 * https://arduino-esp8266.readthedocs.io/en/latest/esp8266wifi/station-class.html
 * https://gist.github.com/bbx10/5a2885a700f30af75fc5
 * https://github.com/esp8266/Arduino/blob/4897e0006b5b0123a2fa31f67b14a3fff65ce561/libraries/ESP8266WiFi/src/include/wl_definitions.h
 * https://github.com/adafruit/Adafruit_MQTT_Library/blob/master/examples/mqtt_esp8266/mqtt_esp8266.ino
 * 
 * https://github.com/lucasmaziero/LiquidCrystal_I2C
 * 
 * https://github.com/jandrassy/ArduinoOTA (search for ArduinoOTA in ide library manager)
 * ToDo:
 * Mac Address in setupFileSystem: : replace : with -
 * 
 * Changelog:
 * v1.3: DisplayMode2 (PULL Data)
 * v1.4: https://github.com/esp8266/Arduino/issues/7613  (exeption after http.end() --> espClient as parameter)
*/
const String nodeVersion="v1.4";
#define ENABLE_ONEWIRE true
#define ENABLE_DHT true
#define ENABLE_LIGHTNESS false
#define ENABLE_RAINFALL false
#define ENABLE_DISPLAY true
#define ENABLE_MQTT false
#define ENABLE_HTTP true
#define ENABLE_OTA true

#ifdef ESP32
#pragma message(THIS EXAMPLE IS FOR ESP8266 ONLY!)
#error Select ESP8266 board.
#endif

#include "dk9mbs_tools.h"
#include <ESP8266WiFi.h>
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

#if ENABLE_MQTT
#include "Adafruit_MQTT.h"
#include "Adafruit_MQTT_Client.h"
#endif

#if ENABLE_OTA
#include <ESP8266mDNS.h>
#include <WiFiUdp.h>
#include <ArduinoOTA.h>
#endif

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

WiFiClient espClient;
ESP8266WebServer httpServer(80);
HTTPClient http;

#if ENABLE_MQTT
Adafruit_MQTT_Client mqtt(&espClient, "", 1883, "", "");
Adafruit_MQTT_Publish sensorTopic = Adafruit_MQTT_Publish(&mqtt, MQTT_PUB_TOPIC, MQTT_QOS_0);
//Adafruit_MQTT_Subscribe displayChanel = Adafruit_MQTT_Subscribe(&mqtt, "node/test", MQTT_QOS_0);
#endif

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
boolean modeDeepSleep=false;
boolean runSetup=false;
long loopDelay=0;
String dspValue1;
String dspValue2;

String restApiUrl;
String restApiUser;
String restApiPwd;
String nodeName;

int state=0; // Status from Statemachine
int transferFailedCount; // count the number of transfer faileds (http)

int displayMode=0; //0=DHT11 1=Remote (Push)

long lastKey1ActionMs=0;
long lastKey1PressedMs=0;
int key1Status=0; //statemachine 

void setup() { 
  Serial.begin(115200);

  //restApiUrl=readConfigValue("restapiurl");
  //restApiUser=readConfigValue("restapiuser");
  //restApiPwd=readConfigValue("restapipwd");
  //nodeName=readConfigValue("hotname");
  transferFailedCount=0;
  
  #if ENABLE_DISPLAY
  lcd.begin(DISPLAY_SDA, DISPLAY_SCL);
  lcd.setCursor(0, 0); // Spalte, Zeile
  printLcd(lcd, 0,0, "booting ...",1);
  printLcd(lcd, 0,1, "Version "+nodeVersion,0);
  delay (1000);
  #endif

  setupIo();
  setupFileSystem();
    
  restApiUrl=readConfigValue("restapiurl");
  restApiUser=readConfigValue("restapiuser");
  restApiPwd=readConfigValue("restapipwd");
  nodeName=readConfigValue("hostname");
  displayMode=readConfigValue("displaymode").toInt();

  Serial.println(restApiUrl);
  Serial.println(restApiUser);
  Serial.print("Displaymode:");
  Serial.println(String(displayMode));
  
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
    return;
  } else {
    #if ENABLE_DISPLAY
    printLcd(lcd, 0,0, "connecting WLAN",1);
    printLcd(lcd, 0,1, "Version "+nodeVersion,0);
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

    #if ENABLE_OTA
    Serial.println("OTA starting ...");
    setupOTA(nodeName);
    Serial.println("OTA started");
    #endif
    
    #if ENABLE_ONEWIRE    
    sensors.begin();
    #endif

    #if ENABLE_DHT
    dht.begin(); 
    #endif

    #if ENABLE_RAINFALL
    attachInterrupt(digitalPinToInterrupt(RAINFALL_PIN), rainfallIsr, RISING);
    #endif

    // attach Reset pin isr
    attachInterrupt(digitalPinToInterrupt(SETUPPIN), buttonIsr, CHANGE);

    delay(500);

    int errCount;
    int httpCode;
    errCount=0;
    httpCode=0;
    
    serverLog(errCount,httpCode, readConfigValue("hostname"), "Node started.");
    if(errCount>0) {
      printLcd(lcd, 0,0, "Log error ("+String(httpCode)+")",1);
      printLcd(lcd, 0,1, "restart the node",0);
      reset(60000);
    }
    #if ENABLE_DISPLAY
    printLcd(lcd, 0,0, "Dsp.Mode:"+String(displayMode),1);
    printLcd(lcd, 0,1, "Version "+nodeVersion,0);
    delay(1000);  
    printLcd(lcd, 0,0, "running ...", 1);
    #endif

  } // run Setup


}

void loop() {
    httpServer.handleClient(); 
    
    #if ENABLE_OTA
    ArduinoOTA.handle();
    #endif
    
    if (runSetup) return;

    if (WiFi.status()!=WL_CONNECTED) {
      saveLastErrorCode(1);
      Serial.print("WiFi status: ");
      Serial.println(WiFi.status());
      printLcd(lcd, 0,0, "WiFi failed!!!", 1);
      printLcd(lcd, 0,1, "Reboot in 30sec", 0);
      reset(30000);   
    }

    int errCount;
    errCount=0;
    
    #if ENABLE_MQTT
    mqttConnect();
    #endif
    
    //mqtt.processPackets(10000);

    // Statemachine
    long now = millis();

    // Setup Button
    int keyPressTime;
    handleKey(SETUPPIN, lastKey1ActionMs, key1Status, lastKey1PressedMs, keyPressTime);
    if(keyPressTime>0){
      Serial.print("Keypress detected:");
      Serial.println(keyPressTime);
      if (keyPressTime<1000) handleSettings(displayMode, false);
      if (keyPressTime>=1000) handleSettings(displayMode, true);
    }
    // Setup Button End



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
      readOneWireTempMultible(errCount);
      #endif

      #if ENABLE_DHT
      String addressHum;
      String addressTemp;
      float valueHum;
      float valueTemp;

      readDhtHum(dht, addressHum, valueHum);
      readDhtTemp(dht,addressTemp, valueTemp);

      if(displayMode==0) {
        dspValue1="T:--C";
        dspValue2="H:--%";
      }
      
      if (!isnan(valueHum)) {
        dspValue1="H:"+String(int(valueHum))+"%";

        #if ENABLE_MQTT  
        publishMqttSensorPayload(sensorTopic, addressHum, valueHum);
        #endif

        #if ENABLE_HTTP
        publishHttpSensorPayload(errCount, addressHum,valueHum);
        #endif    
      } else {
        Serial.println("!Cannot read DHT Hum data");
      }

      if (!isnan(valueTemp)) {
        dspValue2="T:"+String(valueTemp)+"C";

        #if ENABLE_MQTT  
        publishMqttSensorPayload(sensorTopic, addressTemp, valueTemp);
        #endif

        #if ENABLE_HTTP
        publishHttpSensorPayload(errCount, addressTemp,valueTemp);
        #endif    
      } else {
        Serial.println("!Cannot read DHT Temp data");
      }
      
      
      #if ENABLE_DISPLAY
      if(displayMode==0){
        printLcd(lcd, 0,0, String(dspValue2)+" "+String(dspValue1), 1);
        printLcd(lcd, 0,1, "("+String(transferFailedCount)+")", 0);
      }
      #endif
      #endif

      #if ENABLE_LIGHTNESS
        readLightness(address, value);
        #if ENABLE_MQTT
        publishMqttSensorPayload(sensorTopic, address, value);
        #endif
  
        #if ENABLE_HTTP
        publishMqttSensorPayload(errCount, address, value);
        #endif
      #endif

      #if ENABLE_RAINFALL
        readRainfall(address, value);
        #if ENABLE_MQTT
        publishMqttSensorPayload(sensorTopic, address, value);
        #endif
  
        #if ENABLE_HTTP
        publishMqttSensorPayload(errCount, address, value);
        #endif
      #endif

      #if ENABLE_HTTP
      if(displayMode==2) {
        getDisplayData(errCount);
        //printPullData(getDisplayData(errCount));
      }
      #endif
      
      // in case of http errors rebot the node
      if(errCount==0){
        transferFailedCount=0;
      } else {
        transferFailedCount++;
      }
      
      if(transferFailedCount>5) {
        saveLastErrorCode(2);
        printLcd(lcd, 0,0, "Transfer failed",1);
        printLcd(lcd, 0,1, "max. achieved",0);
        Serial.println("HTTP Errors! I will reboot and try it again.");
        Serial.print("HTTP errors:");
        Serial.println(transferFailedCount);
        reset(60000);
      }

      state=2;
    } // Process Task


    // Postprocess
    if(  (now - loopDelay > (modeSleepTimeSec*1000)+POST_TASK_MSSEC  || loopDelay==0) && state==2  ) {
      Serial.println ("Executing post tasks...");
      
      loopDelay = now;
      state=0;

      Serial.println("Post tasks executed");
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


void handleSettings(int & mode, boolean set) {
  static int menuStatus=0; //0=Show DHT11 1=Remote Push 2=Reboot 3=ELAN Status 4=Exit 


  if(set) {
    if(menuStatus==0) {
        printLcd(lcd, 0,0, "EXIT WITHOUT",1);
        printLcd(lcd, 0,1, "CHANGES.",0);
    } else if (menuStatus==1) {
        mode=0; // LOCAL DHT11
        saveConfigValue("displaymode", String(mode));
        printLcd(lcd,0,0,"WAITING FOR DHT",1);
        printLcd(lcd,0,1,"DATA",0);
    } else if(menuStatus==2) {
        mode=1; //Remote PUSH
        saveConfigValue("displaymode", String(mode));
        printLcd(lcd,0,0,"WAITING FOR PUSH",1);
        printLcd(lcd,0,1,"DATA",0);
    } else if (menuStatus==3){
        printLcd(lcd,0,0,"rebooting ...",1);
      ESP.reset();
    } else if (menuStatus==4) {
        printLcd(lcd, 0,0, "WLAN Status:",1);
        printLcd(lcd, 0,1, String(WiFi.status()),0);
    } else if (menuStatus==5) {
        printLcd(lcd, 0,0, "VERSION",1);
        printLcd(lcd, 0,1, String(nodeVersion),0);
    } else if (menuStatus==6) {
        printLcd(lcd, 0,0, "starting task ...",1);
        loopDelay=0;        
    } else if(menuStatus==7) {
        mode=2; // Pull Data
        saveConfigValue("displaymode", String(mode));
        printLcd(lcd,0,0,"WAITING FOR PULL",1);
        printLcd(lcd,0,1,"DATA",0);
    } else if(menuStatus==8) {
        printLcd(lcd,0,0,"DSP. MODE:",1);
        printLcd(lcd,0,1,String(displayMode),0);
    } else if(menuStatus==9) {
        printLcd(lcd,0,0,"IP Address:",1);
        printLcd(lcd,0,1,String(WiFi.localIP().toString()),0);
    }
    return;
  }
  
  menuStatus++;
  if (menuStatus>9) menuStatus=0;

  if( menuStatus==0) {
      printLcd(lcd, 0,0, "EXIT",1);
  } else if (menuStatus==1) {
    printLcd(lcd, 0,0, "LOCAL DHT11",1);
  } else if(menuStatus==2) {
      printLcd(lcd, 0,0, "REMOTE PUSH",1);
  } else if (menuStatus==3){
      printLcd(lcd, 0,0, "REBOOT",1);
  } else if (menuStatus==4){
      printLcd(lcd, 0,0, "WLAN STATUS",1);
  } else if (menuStatus==5) {
      printLcd(lcd, 0,0, "VERSION",1);
  } else if (menuStatus==6) {
      printLcd(lcd, 0,0, "RUN TASK",1);
  } else if (menuStatus==7) {
      printLcd(lcd, 0,0, "PULL DATA",1);
  } else if (menuStatus==8) {
      printLcd(lcd, 0,0, "SHOW DSP.MODE",1);
  } else if (menuStatus==9) {
      printLcd(lcd, 0,0, "SHOW IP",1);
  }
}

void handleKey(int key, long & lastToggleActionMs, int & status, long & lastPressedMs, int & keyPressTime) {
  /*
   * status:
   * 0= start
   * 10=in debonce after keypress
   * 20=in keypress mode 
   * 30=wait for release
   * 40=in debonce after release the key
   */
  long now=millis();
  keyPressTime=0;
  
  // switch first pressed
  if(!digitalRead(key) && status==0 ) {
    status=10;
    lastToggleActionMs=now;
  }

  // in debounce time do nothing (pressed)
  if (now-lastToggleActionMs>DEBOUNCE_TIME_MS && status==10) {
    status=20;
    lastPressedMs=millis();
  }


  // after debounce of keypress
  if (status==20) {
    /*
     * Do some stuff after press the key (run once)
     * 
     */
    status=30;
  }


  // wait for release the button; next go in debonce
  if(status==30 && digitalRead(key)) {
    lastToggleActionMs=millis();
    status=40;
  }

  // after debounce time (release the key)
  if (now-lastToggleActionMs>DEBOUNCE_TIME_MS && status==40) {
    status=0;
    /*
     * Do some stuff after release the key
     */
    keyPressTime=millis()-lastPressedMs;
  }

  
}

#if ENABLE_MQTT
void mqttDisplayCallback(char *data, uint16_t len) {
  Serial.print("Hey we're in a onoff callback, the button value is: ");
  Serial.println(data);
}
#endif

#if ENABLE_DISPLAY
void printLcd(LiquidCrystal_I2C& lcdDisplay,int column, int row, String text, int clear) {
  if(clear==1) lcdDisplay.clear();
  
  lcdDisplay.setCursor(column, row); // Spalte, Zeile
  lcdDisplay.print(text);
}
#endif

ICACHE_RAM_ATTR void buttonIsr() {
    
}

#if ENABLE_RAINFALL
ICACHE_RAM_ATTR void rainfallIsr() {
  int now=millis();
  if(now-lastrainfallSignal < DEBOUNCE_TIME_MS) return;
  
  rainfallCount++;
  lastrainfallSignal=millis();

  //Serial.print("Rain:");
  //Serial.println(rainfallCount);
}

void readRainfall(String& address, float& value) {
  Serial.println("reading the Rainfall sensor");
  address=createIoTDeviceAddress("rainfall");
  value=rainfallCount;

}
#endif

#if ENABLE_MQTT
void publishMqttSensorPayload(Adafruit_MQTT_Publish& topic, String address, float value) {
  String payload="";
  payload = "{\"value\":"+String(value)+", \"address\":\""+address+"\"}";
  topic.publish(payload.c_str());
}
#endif

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
  //Serial.print(dht.getStatusString());

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
void readOneWireTempMultible(int & errCount) {
  Serial.println("reading the onewire sensors...");

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
    Serial.println("ºC : sending ... ");

    dtostrf(temperatureC,7, 3, temperaturenow);  //// convert float to char

    #if ENABLE_MQTT
    publishMqttSensorPayload(sensorTopic, address,temperatureC); 
    #endif

    #if ENABLE_HTTP
    publishHttpSensorPayload(errCount,address,temperatureC); 
    #endif
  }
}
#endif

#if ENABLE_MQTT
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
  
  if(staticBroker!="") {
    Serial.println("use static mqtt broker address!");
    mqttBroker=staticBroker;
    mqttPort=readConfigValue("staticbrokerport").toInt();
  } else {
    Serial.println("!Pse enter a valid broker address!");
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
#endif
// http server
void setupHttpAdmin() {
  httpServer.on("/",handleHttpSetup);
  httpServer.on("/api",handleHttpApi);
  httpServer.on("/version",handleHttpVersion);
  httpServer.on("/setdisplay",handleHttpSetDisplay);
  httpServer.onNotFound(handleHttp404);
  httpServer.begin();
}

void handleHttpApi() {
  httpServer.send(200, "text/html", "api"); 
}

void handleHttpVersion() {
  httpServer.send(200, "text/html", "{\"version\": \""+nodeVersion+"\"}"); 
}

void handleHttpSetDisplay() {
  if(httpServer.hasArg("line1")) {
      printLcd(lcd, 0,0, httpServer.arg("line1"),1);
  } else {
      printLcd(lcd, 0,0, "NO DATA",1);
  }

  if(httpServer.hasArg("line2")) {
      printLcd(lcd, 0,1, httpServer.arg("line2"),0);
  } else {
      printLcd(lcd, 0,1, "** dk9mbs.de **",0);
  }

  httpServer.send(200, "text/html", "{\"result\": \"OK\"}"); 
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
    "<title>DK9MBS/AG5ZL IoT Sensor</title>"
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
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>MQTT broker address</div><INPUT style=\"width:99%;\" type=\"text\" name=\"STATICBROKERADDR\" value=\""+ readConfigValue("staticbrokeraddr") +"\"></div>"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>MQTT broker port</div><INPUT style=\"width:99%;\" type=\"text\" name=\"STATICBROKERPORT\" value=\""+ readConfigValue("staticbrokerport") +"\"></div>"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>Username</div><INPUT style=\"width:99%;\" type=\"text\" name=\"BROKERUSER\" value=\""+ readConfigValue("brokeruser") +"\"></div>"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>Password</div><INPUT style=\"width:99%;\" type=\"text\" name=\"BROKERPWD\" value=\""+ readConfigValue("brokerpwd") +"\"></div>"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>Publish topic</div><INPUT disabled maxlength=\"50\" style=\"width:99%;\" type=\"text\" name=\"PUBTOPIC\" value=\""+ MQTT_PUB_TOPIC +"\"></div>"
    "</P>"
    "<P>RestAPI"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>RestAPI URL (for example: http://192.168.2.123:5000/api/v1.0/)</div><INPUT style=\"width:99%;\" type=\"text\" name=\"RESTAPIURL\" value=\""+ readConfigValue("restapiurl") +"\"></div>"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>RestAPI User</div><INPUT style=\"width:99%;\" type=\"text\" name=\"RESTAPIUSER\" value=\""+ readConfigValue("restapiuser") +"\"></div>"
    "<div style=\"border-style: solid; border-width:thin; border-color: #000000;padding: 2px;margin: 1px;\"><div>RestAPI Password</div><INPUT style=\"width:99%;\" type=\"text\" name=\"RESTAPIPWD\" value=\""+ readConfigValue("restapipwd") +"\"></div>"
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

  saveConfigValue("restapiurl", httpServer.arg("RESTAPIURL"));
  saveConfigValue("restapiuser", httpServer.arg("RESTAPIUSER"));
  saveConfigValue("restapipwd", httpServer.arg("RESTAPIPWD"));

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
  if(!SPIFFS.exists(getConfigFilename("mode"))) saveConfigValue("mode", "loop");//deepsleep or loop
  if(!SPIFFS.exists(getConfigFilename("sleeptime"))) saveConfigValue("sleeptime", "60");
  if(!SPIFFS.exists(getConfigFilename("adminpwd"))) saveConfigValue("adminpwd", "123456789ff");

  if(!SPIFFS.exists(getConfigFilename("staticbrokeraddr"))) saveConfigValue("staticbrokeraddr", "192.168.4.1");
  if(!SPIFFS.exists(getConfigFilename("staticbrokerport"))) saveConfigValue("staticbrokerport", "1883");

  if(!SPIFFS.exists(getConfigFilename("brokeruser"))) saveConfigValue("brokeruser", "username");
  if(!SPIFFS.exists(getConfigFilename("brokerpwd"))) saveConfigValue("brokerpwd", "password");
  if(!SPIFFS.exists(getConfigFilename("hostname"))) saveConfigValue("hostname", "node");
  if(!SPIFFS.exists(getConfigFilename("pubtopic"))) saveConfigValue("pubtopic", "temp/sensor");

  if(!SPIFFS.exists(getConfigFilename("restapiurl"))) saveConfigValue("restapiurl", "http://192.168.2.111:5000/api/v1.0/");
  if(!SPIFFS.exists(getConfigFilename("restapiuser"))) saveConfigValue("restapiuser", "root");
  if(!SPIFFS.exists(getConfigFilename("restapipwd"))) saveConfigValue("restapipwd", "password");

  if(!SPIFFS.exists(getConfigFilename("displaymode"))) saveConfigValue("displaymode", "0");

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
  WiFi.setSleepMode(WIFI_NONE_SLEEP); //new
  
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


void reset(int msDelay) {
  delay(msDelay);
  // basically die and wait for WDT to reset me
  while (1);
}

#if ENABLE_HTTP
void serverLog(int & errCount, int & httpCode, String node, String message) {
  int lastErrorCode=getLastErrorCode();
  
  http.begin(espClient, readConfigValue("restapiurl")+"data/iot_log");
  http.addHeader("username", readConfigValue("restapiuser"));
  http.addHeader("password", readConfigValue("restapipwd"));
  http.addHeader("Content-Type", "application/json");

  httpCode=http.POST("{\"name\": \""+node+"\", \"message\": \""+message+" ("+String(getLastErrorCode())+")\", \"source_id\":\"1\", \"node_name\": \""+node+"\",\"ip_address\":\""+WiFi.localIP().toString()+"\" }");

  if(httpCode==200) {
    clearLastErrorCode();
    Serial.println("Log sended");
  } else {
    Serial.println("!cannot send logdata:"+String(httpCode)); 
    errCount++;
  }
  http.end();
}


void publishHttpSensorPayload(int & errCount, String address, float value) {
  String payload="";
  payload = "{\"sensor_value\":"+String(value)+", \"sensor_id\":\""+address+"\", \"sensor_namespace\":\"restapi\"  }";
  Serial.println("====================================");
  Serial.println("publishing sensor data via http");
  
  http.begin(espClient, restApiUrl+"data/iot_sensor_data");
  http.addHeader("username", restApiUser);
  http.addHeader("password", restApiPwd);
  http.addHeader("Content-Type", "application/json");
  
  int httpCode=http.POST( payload   );

  if(httpCode==200) {
    Serial.println("Sensordata sended");
  } else {
    Serial.println("cannot transfer sensordata. I will reboot in postprocess"); 
    errCount++;
    Serial.print("ErrCount:");
    Serial.println(errCount);
  }
  http.end();
  Serial.println("====================================");

}

void getDisplayData(int & errCount) {
    http.begin(espClient, restApiUrl+"action/iot_get_node_display_text");
    http.addHeader("restapi-username", restApiUser);
    http.addHeader("restapi-password", restApiPwd);
    http.addHeader("Content-Type", "application/json");

    int httpCode=http.POST("{\"node_name\":\""+nodeName+"\"}");
    if(httpCode==200) {
      //String line1=split(http.getString(), ';', 0);
      //String line2=split(http.getString(), ';', 1);
      const String& payload=http.getString();
      const String& line1=payload.substring(0,payload.indexOf(';'));
      const String& line2=payload.substring(payload.indexOf(';')+1,payload.length());
      
      //Serial.println(http.getString());
      //Serial.println(line1);
      //Serial.println(line2);
      
      printLcd(lcd, 0,0, line1,1);
      printLcd(lcd, 0,1, line2,0);
      
    } else {
      errCount++; 
      printLcd(lcd, 0,0, String(httpCode),1);
    }

    Serial.print("HTTP Code (get display):");
    Serial.println(httpCode);

    http.end();

    Serial.println("after http.end()");
}

/*
void printPullData(String command) {
  printLcd(lcd, 0,0, command,1);
  printLcd(lcd, 0,1, "**** DK9MBS ****",0);
}
*/
#endif

#if ENABLE_OTA
void setupOTA(String& hostName) {
  // Port defaults to 8266
  // ArduinoOTA.setPort(8266);

  // Hostname defaults to esp8266-[ChipID]
  // ArduinoOTA.setHostname("node-labor");

  // No authentication by default
  // ArduinoOTA.setPassword("admin");

  // Password can be set with it's md5 value as well
  // MD5(admin) = 21232f297a57a5a743894a0e4a801fc3
  // ArduinoOTA.setPasswordHash("21232f297a57a5a743894a0e4a801fc3");

  ArduinoOTA.onStart([]() {
    String type;
    if (ArduinoOTA.getCommand() == U_FLASH) {
      type = "sketch";
    } else { // U_FS
      type = "filesystem";
    }

    // NOTE: if updating FS this would be the place to unmount FS using FS.end()
    Serial.println("Start updating " + type);
  });
  ArduinoOTA.onEnd([]() {
    Serial.println("\nEnd");
  });
  ArduinoOTA.onProgress([](unsigned int progress, unsigned int total) {
    Serial.printf("Progress: %u%%\r", (progress / (total / 100)));
  });
  ArduinoOTA.onError([](ota_error_t error) {
    Serial.printf("Error[%u]: ", error);
    if (error == OTA_AUTH_ERROR) {
      Serial.println("Auth Failed");
    } else if (error == OTA_BEGIN_ERROR) {
      Serial.println("Begin Failed");
    } else if (error == OTA_CONNECT_ERROR) {
      Serial.println("Connect Failed");
    } else if (error == OTA_RECEIVE_ERROR) {
      Serial.println("Receive Failed");
    } else if (error == OTA_END_ERROR) {
      Serial.println("End Failed");
    }
  });
  ArduinoOTA.begin();
}
#endif
