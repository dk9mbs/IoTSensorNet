#include "dk9mbs_tools.h"
#include "dk9mbs_config.h"

#include <WiFiUdp.h>
WiFiUDP udp;

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
