///File name  : main.dart
///Author     : Sabari Kannan M.
///Created on : 07/06/2021
///Last edit  : 22/07/2021

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_bin/globals.dart';
import 'package:smart_bin/mqtt.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

final String appTitle = "Smart-bin app";
final String smartBinStatus = "assets/images/good_bin.jpg";

final String param1 = "Air quality";
final String param2 = "Bin level";

int roundIAQ = 50;
int binLevelThreshold = 75;
int airQualityThreshold = 101;

// time in utc
var dateUtc = DateTime.now().toUtc();
// convert it to local
var dateLocal = dateUtc.toLocal();
var lastBinLevelNotificationTime = dateLocal;
var lastBinAirQualityNotificationTime = dateLocal;
bool firstBinLevelNotification = true;
bool firstBinAirQualityNotification = true;

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  Timer? timer;

  @override
  void initState() {
    initializeSetting();
    tz.initializeTimeZones();
    super.initState();
    timer =
        Timer.periodic(Duration(seconds: 1), (Timer t) => setStateCallback());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void setStateCallback() {
    roundAirQuality(airQualityIndexDouble.toInt());

    // time in utc
    dateUtc = DateTime.now().toUtc();
    // convert it to local
    dateLocal = dateUtc.toLocal();

    ///show notifications
    Duration difference2 = dateLocal.difference(lastBinLevelNotificationTime);
    if (binLevel >= binLevelThreshold && firstBinLevelNotification) {
      print('first bin level notification');
      lastBinLevelNotificationTime = dateLocal;
      binLevelNotification(binLevel);
      firstBinLevelNotification = false;
    } else if (((binLevel < binLevelThreshold) &&
            (!firstBinLevelNotification)) ||
        ((binLevel >= binLevelThreshold) && (difference2.inSeconds > 10))) {
      print('get ready for next notification/repeated notification');
      firstBinLevelNotification = true;
    }

    Duration difference3 =
        dateLocal.difference(lastBinAirQualityNotificationTime);
    if (airQualityIndexDouble >= airQualityThreshold &&
        firstBinAirQualityNotification) {
      lastBinAirQualityNotificationTime = dateLocal;
      binAirQualityNotification(airQualityIndexDouble);
      firstBinAirQualityNotification = false;
    } else if (((airQualityIndexDouble < airQualityThreshold) &&
            (!firstBinAirQualityNotification)) ||
        ((airQualityIndexDouble >= airQualityThreshold) &&
            (difference3.inSeconds == 10))) {
      print('get ready for next notification/repeated notification');
      firstBinAirQualityNotification = true;
    }
    setState(() {});
  }

  ///round IAQ
  void roundAirQuality(int valueIAQ) {
    if ((valueIAQ >= 0) && (valueIAQ <= 50))
      roundIAQ = 50;
    else if ((valueIAQ >= 51) && (valueIAQ <= 100))
      roundIAQ = 100;
    else if ((valueIAQ >= 101) && (valueIAQ <= 150))
      roundIAQ = 150;
    else if ((valueIAQ >= 151) && (valueIAQ <= 200))
      roundIAQ = 200;
    else if ((valueIAQ >= 201) && (valueIAQ <= 250))
      roundIAQ = 250;
    else if ((valueIAQ >= 251) && (valueIAQ <= 350))
      roundIAQ = 350;
    else if (valueIAQ > 350)
      roundIAQ = 351;
    else
      roundIAQ = 50;
  }

  ///update bin data on screen
  void refreshDataOnScreen() {
    if (binCounter == 1) {
      airQualityIndexDouble = airQuality1;
      binLevel = binLevel1;
    } else if (binCounter == 2) {
      airQualityIndexDouble = airQuality2;
      binLevel = binLevel2;
    } else if (binCounter == 3) {
      airQualityIndexDouble = airQuality3;
      binLevel = binLevel3;
    } else if (binCounter == 4) {
      airQualityIndexDouble = airQuality4;
      binLevel = binLevel4;
    }
    roundAirQuality(airQualityIndexDouble.toInt());
  }

  @override
  Widget build(BuildContext context) {
    if (!mqttConnected) mqttConnect(); //MQTT connect
    refreshDataOnScreen();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(appTitle),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Smart Bin $binCounter data',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  RaisedButton.icon(
                      color: Colors.lightBlueAccent,
                      onPressed: () {
                        setState(() {
                          if (binCounter < 4)
                            binCounter++;
                          else
                            binCounter = 1;
                          //print('$SB1_topic$binCounter');
                          selectedTopic = '$SB1_topic$binCounter';
                          print('$selectedTopic');
                        });
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: Text("Change smart bin")),
                ],
              ),
            ),

            ///display sensor data
            Container(
              margin: const EdgeInsets.fromLTRB(0, 20, 0, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ///bin IAQ
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ///display IAQ icon
                        Image(
                          gaplessPlayback: true,
                          image:
                              AssetImage('assets/images/IAQ/IAQ_$roundIAQ.png'),
                        ),

                        ///display IAQ value
                        Container(
                          margin: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                          child: Text(
                            'IAQ: $airQualityIndexDouble',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              //letterSpacing: 2.0
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  ///bin level
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ///display bin level icon
                        Image(
                          gaplessPlayback: true,
                          image: AssetImage(
                              'assets/images/Bin_level/Bin_level_$binLevel.png'),
                        ),

                        ///display bin level value
                        Container(
                          margin: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                          child: Text(
                            'Level: $binLevel%',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///bin air quality notification
  Future<void> binAirQualityNotification(double airQualityIndexValue) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'your channel id', 'your channel name', 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await notificationsPlugin.show(
        0,
        'Bin air quality',
        'Your bin air quality index is $airQualityIndexValue !',
        platformChannelSpecifics,
        payload: 'item x');
  }

  ///bin level notification
  Future<void> binLevelNotification(int binLevel2) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'your channel id', 'your channel name', 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await notificationsPlugin.show(1, 'Bin level',
        'Your bin level is $binLevel2 !', platformChannelSpecifics,
        payload: 'item x 2');
  }
}

void initializeSetting() async {
  var initializeAndroid = AndroidInitializationSettings("notification_icon");
  var initializeSettings = InitializationSettings(android: initializeAndroid);
  await notificationsPlugin.initialize(initializeSettings);
}
