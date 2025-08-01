// ignore_for_file: avoid_print

import 'package:affection_alerts/env/envied.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Global variables to store current message state
String? currentMessageBody;
String? currentMessageTimeAgo;

/// Analyzes chat messages and extracts cute/heartwarming messages using a scoring system
Future<List<String>> analyzeCuteMessages(String chatMessages) async {
  // Define scoring weights for different types of content
  final Map<String, int> loveWords = {
    'love': 5,
    'adore': 4,
    'cherish': 4,
    'treasure': 4,
    'worship': 4,
    'devotion': 3,
    'affection': 3,
    'romance': 3,
    'passion': 4,
  };

  final Map<String, int> missWords = {
    'miss': 4,
    'missing': 4,
    'thinking of': 3,
    'thinking about': 3,
    'can\'t stop thinking': 5,
    'dream about': 4,
    'dreaming of': 4,
    'remember': 2,
    'reminds me': 3,
    'wish you were': 4,
  };

  final Map<String, int> compliments = {
    'beautiful': 4,
    'gorgeous': 4,
    'stunning': 4,
    'breathtaking': 5,
    'amazing': 3,
    'incredible': 3,
    'wonderful': 3,
    'perfect': 3,
    'fantastic': 3,
    'extraordinary': 4,
    'magnificent': 4,
    'handsome': 4,
    'cute': 3,
    'adorable': 4,
    'lovely': 3,
    'charming': 3,
    'attractive': 3,
    'sexy': 3,
    'hot': 2,
  };

  final Map<String, int> emotionalWords = {
    'happy': 3,
    'joy': 3,
    'smile': 2,
    'laugh': 2,
    'giggle': 2,
    'excited': 3,
    'thrilled': 4,
    'blessed': 3,
    'grateful': 3,
    'thankful': 3,
    'appreciate': 2,
    'lucky': 2,
    'fortunate': 2,
    'proud': 3,
    'impressed': 2,
    'amazed': 3,
    'touched': 3,
    'moved': 3,
    'overwhelmed': 3,
    'speechless': 3,
  };

  final Map<String, int> supportWords = {
    'believe in': 3,
    'proud of': 4,
    'support': 2,
    'here for': 3,
    'always there': 4,
    'count on': 3,
    'trust': 2,
    'faith': 2,
    'confident': 2,
    'encourage': 2,
    'inspire': 3,
    'motivate': 2,
  };

  final Map<String, int> endearmentTerms = {
    'babe': 2,
    'baby': 2,
    'honey': 2,
    'sweetie': 2,
    'sweetheart': 3,
    'darling': 3,
    'love': 2,
    'dear': 2,
    'angel': 3,
    'princess': 3,
    'prince': 3,
    'sunshine': 3,
    'beautiful': 2,
    'gorgeous': 2,
  };

  final Map<String, int> futureWords = {
    'can\'t wait': 4,
    'looking forward': 3,
    'excited to': 3,
    'future': 2,
    'together': 3,
    'forever': 4,
    'always': 3,
    'marry': 5,
    'wedding': 4,
    'kids': 3,
    'family': 3,
  };

  final Map<String, int> emojiScores = {
    '❤️': 5,
    '💕': 4,
    '💖': 4,
    '💗': 4,
    '💓': 4,
    '💞': 4,
    '💝': 3,
    '💘': 4,
    '😘': 3,
    '😗': 2,
    '😙': 2,
    '😚': 3,
    '🥰': 4,
    '😍': 3,
    '🤩': 3,
    '😻': 4,
    '💋': 3,
    '🌹': 3,
    '🌺': 2,
    '🌸': 2,
    '🌻': 2,
    '✨': 2,
    '⭐': 2,
    '🌟': 2,
    '💫': 2,
    '🦋': 2,
    '🎈': 1,
    '🎉': 2,
    '🥳': 2,
    '😊': 1,
    '😄': 1,
    '😃': 1,
    '🙂': 1,
    '☺️': 1,
    '🤗': 2,
    '🫶': 4,
  };

  // Phrases that indicate special occasions or meaningful moments
  final List<String> specialPhrases = [
    'good morning',
    'good night',
    'sweet dreams',
    'sleep tight',
    'have a great day',
    'thinking of you',
    'made my day',
    'you\'re the best',
    'couldn\'t ask for more',
    'mean everything',
    'world to me',
    'life is better',
    'make me complete',
    'other half',
    'soulmate',
    'meant to be',
    'destiny',
  ];

  final List<String> lines = chatMessages.split('\n');
  final List<MapEntry<String, int>> scoredMessages = [];

  for (String line in lines) {
    // Check if this line is from the partner
    if (line.contains('${Env.partnerName}:')) {
      // Parse WhatsApp format: [MM/dd/yy, HH:mm:ss] Partner Name: Message
      final RegExp whatsappPattern = RegExp(r'\[(.*?)\]\s*(.*?):\s*(.*)');
      final Match? match = whatsappPattern.firstMatch(line);

      if (match != null) {
        final timestamp = match.group(1)!;
        final senderName = match.group(2)!;
        final message = match.group(3)!;

        // Skip if not from partner or message is too short
        if (senderName != Env.partnerName || message.trim().length < 3) {
          continue;
        }

        int score = 0;
        final messageLower = message.toLowerCase();

        // Score based on different word categories
        score += _scoreWords(messageLower, loveWords);
        score += _scoreWords(messageLower, missWords);
        score += _scoreWords(messageLower, compliments);
        score += _scoreWords(messageLower, emotionalWords);
        score += _scoreWords(messageLower, supportWords);
        score += _scoreWords(messageLower, endearmentTerms);
        score += _scoreWords(messageLower, futureWords);

        // Score based on emojis
        emojiScores.forEach((emoji, points) {
          final count = emoji.allMatches(message).length;
          score += points * count;
        });

        // Score based on special phrases
        for (String phrase in specialPhrases) {
          if (messageLower.contains(phrase.toLowerCase())) {
            score += 2;
          }
        }

        // Bonus scoring factors

        // Length bonus (longer messages often more meaningful)
        if (message.length > 50) score += 1;
        if (message.length > 100) score += 2;
        if (message.length > 200) score += 1;

        // Multiple sentences bonus
        if (message.split('.').length > 2) score += 1;
        if (message.split('!').length > 2) score += 1;

        // Question bonus (shows interest)
        if (message.contains('?')) score += 1;

        // Repetition bonus (emphasis like "love love love")
        final words = messageLower.split(' ');
        final wordCounts = <String, int>{};
        for (String word in words) {
          if (word.length > 3) {
            wordCounts[word] = (wordCounts[word] ?? 0) + 1;
          }
        }
        for (int count in wordCounts.values) {
          if (count > 1) score += count - 1;
        }

        // Time-based bonus (messages sent at special times)
        try {
          final parsedTime = DateFormat('MM/dd/yy, HH:mm:ss').parse(timestamp);
          final hour = parsedTime.hour;

          // Late night/early morning messages (more intimate)
          if (hour >= 23 || hour <= 6) score += 1;

          // Good morning messages (7-9 AM)
          if (hour >= 7 && hour <= 9 && messageLower.contains('morning'))
            score += 2;

          // Good night messages (9-11 PM)
          if (hour >= 21 &&
              hour <= 23 &&
              (messageLower.contains('night') ||
                  messageLower.contains('sleep'))) score += 2;
        } catch (e) {
          debugPrint('Error parsing timestamp: $timestamp');
        }

        // Only include messages with a meaningful score
        if (score >= 4) {
          // Adjust threshold as needed
          scoredMessages.add(MapEntry('${message.trim()}~$timestamp', score));
        }
      }
    }
  }

  // Sort by score (highest first) and return formatted messages
  scoredMessages.sort((a, b) => b.value.compareTo(a.value));

  debugPrint('Found ${scoredMessages.length} cute messages');
  for (var entry in scoredMessages.take(10)) {
    debugPrint('Score ${entry.value}: ${entry.key}');
  }

  return scoredMessages.map((entry) => entry.key).toList();
}

/// Helper function to score words in a message
int _scoreWords(String message, Map<String, int> wordScores) {
  int score = 0;
  wordScores.forEach((word, points) {
    if (message.contains(word.toLowerCase())) {
      score += points;
    }
  });
  return score;
}

/// Main function to get next cute message and schedule notifications
Future nextMessage() async {
  try {
    // Cancel all scheduled notifications
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.cancel(0);
    tz.initializeTimeZones();

    // Load chat messages
    String chatMessages =
        await rootBundle.loadString('assets/whatsapp_chat.txt');

    debugPrint('Loaded chat messages, analyzing for cute content...');

    // Analyze messages for cute content
    List<String> resultList = await analyzeCuteMessages(chatMessages);

    if (resultList.isEmpty) {
      debugPrint('No cute messages found with current criteria');
      // Fallback: try with lower threshold or different analysis
      return;
    }

    debugPrint('Found ${resultList.length} cute messages to schedule');

    int currentId = 1;
    int scheduledCount = 0;
    const int maxNotifications = 10; // Limit number of notifications

    for (var element in resultList.take(maxNotifications)) {
      List<String> bodyDate = element.split('~');

      // Skip if the format is incorrect
      if (bodyDate.length < 2) {
        debugPrint('Skipping malformed element: $element');
        continue;
      }

      debugPrint('Scheduling notification $currentId: ${bodyDate[0]}');

      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          currentId, // ID of the notification
          timeago.format(convertToDate(bodyDate[1])), // Title (time ago)
          bodyDate[0].trim(), // Body (the cute message)
          tz.TZDateTime.now(tz.local)
              .add(Duration(days: 7 * currentId)), // Scheduled time (weekly)
          const NotificationDetails(
              android: AndroidNotificationDetails(
                'cute_messages_channel',
                'Cute Messages',
                channelDescription: 'Sweet messages from your partner',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: DarwinNotificationDetails(
                sound: 'default',
                badgeNumber: 1,
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              )),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        currentId += 1;
        scheduledCount += 1;
      } catch (e) {
        debugPrint('Error scheduling notification for element: $element');
        debugPrint('Error: $e');
      }
    }

    debugPrint('Successfully scheduled $scheduledCount notifications');

    // Set the first valid result as current message for display
    if (resultList.isNotEmpty) {
      String selectedResult = resultList[0];
      List<String> selectedResultComponent = selectedResult.split('~');

      if (selectedResultComponent.length >= 2) {
        currentMessageBody = selectedResultComponent[0].trim();
        currentMessageTimeAgo = timeago.format(
          convertToDate(selectedResultComponent[1]),
        );

        debugPrint('Current message set: $currentMessageBody');
        debugPrint('Time ago: $currentMessageTimeAgo');
      } else {
        debugPrint('First result is malformed: $selectedResult');
      }
    }
  } catch (e) {
    debugPrint('Error in nextMessage function: $e');
  }
}

/// Convert date string to DateTime object
DateTime convertToDate(String dateString) {
  try {
    // Handle different possible date formats
    DateFormat format;

    // Try MM/dd/yy, HH:mm:ss format first
    if (dateString.contains('/') && dateString.contains(',')) {
      format = DateFormat('MM/dd/yy, HH:mm:ss');
    } else if (dateString.contains('-')) {
      // Handle yyyy-MM-dd HH:mm:ss format
      format = DateFormat('yyyy-MM-dd HH:mm:ss');
    } else {
      // Default format
      format = DateFormat('MM/dd/yy, HH:mm:ss');
    }

    DateTime dateTime = format.parse(dateString);
    return dateTime;
  } catch (e) {
    debugPrint('Error parsing date: $dateString, Error: $e');
    // Return current time as fallback
    return DateTime.now();
  }
}
