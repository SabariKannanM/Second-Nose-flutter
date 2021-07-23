library globals;
import 'dart:convert';

int airQualityIndex = 0;  //index for air quality
double airQualityIndexDouble = 0.0;
int binLevel = 0; //waste level in the bin
bool mqttConnected = false; //true - connected, false - not connected
int binCounter = 1;

double airQuality1 = 50;
double airQuality2 = 100;
double airQuality3 = 150;
double airQuality4 = 200;

int binLevel1 = 10;
int binLevel2 = 20;
int binLevel3 = 30;
int binLevel4 = 40;

const SB1_topic = 'topic'; // subscribe topic
const SB2_topic = 'topic2'; // subscribe topic2
const SB3_topic = 'topic3'; // subscribe topic3
const SB4_topic = 'topic4'; // subscribe topic4

String selectedTopic = SB1_topic;