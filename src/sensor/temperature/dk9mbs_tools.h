#ifndef DK9MBS_TOOLS_H
#define DK9MBS_TOOLS_H


#include <DallasTemperature.h>


void saveConfigValue(String name, String value);

String readConfigValue(String name);

String getConfigFilename(String name);

String split(String s, char parser, int index);

void parseBytes(const char* str, char sep, byte* bytes, int maxBytes, int base);

String deviceAddress2String(DeviceAddress deviceAddress);

void saveLastErrorCode(int errorCode);

int getLastErrorCode();

void clearLastErrorCode();

boolean stringToBool(const char* str);
#endif
