#include <FS.h>
#include "dk9mbs_tools.h"

#include <DallasTemperature.h>

const String lastErrorFileName="/lasterr.txt";

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

void saveConfigValue(String name, String value) {
  File f =SPIFFS.open("/"+name+".cfg","w");
  f.print(value.c_str());
  f.close();
  Serial.print("Saved config value:");
  Serial.print(name+" -> ");
  Serial.println(readConfigValue(name));
}

String getConfigFilename(String name) {
  return "/"+name+".cfg";
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

/*
 * errCode:
 * 0=Cleared error
 * 1=WiFi
 * 2=HTTP transfer error
 */
void saveLastErrorCode(int errCode) {
  File f = SPIFFS.open(lastErrorFileName,"w");
  f.print(errCode);
  f.close();
}

void clearLastErrorCode() {
  if (SPIFFS.exists(lastErrorFileName)) {
    File f = SPIFFS.open(lastErrorFileName,"w");
    f.print("0");
    f.close();  
  }
}

int getLastErrorCode() {
  String result;
  
  if (!SPIFFS.exists(lastErrorFileName)) {
    return 0;
  } else {
    File f = SPIFFS.open(lastErrorFileName,"r");
    result=f.readString();
    f.close();  
  }

  result.replace("\n", "");
  result.replace("\r", "");
  result.replace("\t", "");
  return result.toInt();
}

boolean stringToBool(const char* str){
  if(str=="0") {
    return false;
  } else {
    return true;
  }
}
