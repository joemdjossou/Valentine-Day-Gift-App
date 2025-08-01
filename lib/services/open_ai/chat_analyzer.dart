// ignore_for_file: avoid_print

import 'package:affection_alerts/env/envied.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

String? currentMessageBody;
String? currentMessageTimeAgo;

Future nextMessage() async {
  // Cancel all scheduled notifications
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.cancel(0);
  tz.initializeTimeZones();

  String chatMessages = await rootBundle.loadString('assets/whatsapp_chat.txt');

  String prompt = """
    Given the following list of messages and their send dates, identify messages sent by ${Env.partnerName} that are very cute and heart warming and provide the send date for each cute message:
    $chatMessages
    
    Please format your response EXACTLY as follows, with each message on a new line:
    "<Message Content>~<Send Date>"
    
    For example:
    "I love you so much!~12/25/23, 14:30:15"
    "You make me so happy~12/26/23, 09:15:22"
    
    Only include messages from ${Env.partnerName} that are genuinely cute and heartwarming.
    """;

  OpenAIChatCompletionModel completion = await OpenAI.instance.chat.create(
    model: "gpt-4",
    messages: [
      OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            prompt,
          ),
        ],
        role: OpenAIChatMessageRole.user,
      )
    ],
  );

  OpenAIChatCompletionChoiceMessageContentItemModel content =
      completion.choices.first.message.content!.first;

  List<String> resultList = content.text!.split('\n');

  // Filter out empty lines and lines that don't contain the expected format
  resultList = resultList
      .where((element) => element.trim().isNotEmpty && element.contains('~'))
      .toList();

  debugPrint('AI Response: ${content.text}');
  debugPrint('Filtered results: $resultList');

  if (resultList.isEmpty) {
    debugPrint('No valid messages found in AI response');
    return;
  }

  int currentId = 1;

  for (var element in resultList) {
    List<String> bodyDate = element.split('~');

    // Skip if the format is incorrect
    if (bodyDate.length < 2) {
      debugPrint('Skipping malformed element: $element');
      continue;
    }

    debugPrint('Scheduling $element $currentId');

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        currentId, // ID of the notification
        timeago.format(convertToDate(bodyDate[1])), // Title
        bodyDate[0], // Body
        tz.TZDateTime.now(tz.local)
            .add(Duration(days: 7 * currentId)), // Scheduled time
        const NotificationDetails(
            iOS: DarwinNotificationDetails(
          sound: 'default',
          badgeNumber: 1,
          // other properties
        )),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      currentId += 1;
    } catch (e) {
      debugPrint('Error scheduling notification for element: $element');
      debugPrint('Error: $e');
    }
  }

  // Set the first valid result as current message
  String selectedResult = resultList[0];
  List<String> selectedResultComponent = selectedResult.split('~');

  if (selectedResultComponent.length >= 2) {
    debugPrint(resultList.toString());
    debugPrint(selectedResult.toString());
    debugPrint(selectedResultComponent.toString());
    debugPrint(convertToDate(selectedResultComponent[1]).toString());

    currentMessageBody = selectedResultComponent[0];
    currentMessageTimeAgo = timeago.format(
      convertToDate(selectedResultComponent[1]),
    );
  } else {
    debugPrint('First result is malformed: $selectedResult');
  }
}

DateTime convertToDate(String dateString) {
  // Define the format of the input date string
  DateFormat format = DateFormat('MM/dd/yy, HH:mm:ss');
  // Use the format to parse the input string into a DateTime object
  DateTime dateTime = format.parse(dateString);
  return dateTime;
}
