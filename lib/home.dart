import 'package:affection_alerts/env/envied.dart';
// OpenAI Chat Analyzer (AI Finetuning) 🦾🤖
// import 'package:affection_alerts/services/open_ai/chat_analyzer.dart';
// Manual Finetuning Chat Analyzer (Local) 🤓🤓
import 'package:affection_alerts/services/manual_finetuning/chat_analyzer_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timeago/timeago.dart' as timeago;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  String sender = "${Env.partnerName} ❤️";
  static const Color textColor = Color(0xFFE42A53);
  bool isLoading = false;

  // Store all cute messages
  List<Map<String, String>> allMessages = [];
  int currentMessageIndex = 0;
  PageController pageController = PageController();

  late AnimationController _stackAnimationController;
  late AnimationController _paperAnimationController;

  @override
  void initState() {
    _stackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _paperAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    requestPermission();
    super.initState();
  }

  @override
  void dispose() {
    _stackAnimationController.dispose();
    _paperAnimationController.dispose();
    pageController.dispose();
    super.dispose();
  }

  requestPermission() async {
    setState(() {
      isLoading = true;
    });

    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    await loadAllMessages();
  }

  Future<void> loadAllMessages() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get all cute messages from the analyzer
      String chatMessages =
          await rootBundle.loadString('assets/whatsapp_chat.txt');
      List<String> resultList = await analyzeCuteMessages(chatMessages);

      // Parse messages into structured format
      allMessages.clear();
      for (String element in resultList) {
        List<String> bodyDate = element.split('~');
        if (bodyDate.length >= 2) {
          allMessages.add({
            'message': bodyDate[0].trim(),
            'timestamp': bodyDate[1],
            'timeAgo': timeago.format(convertToDate(bodyDate[1])),
          });
        }
      }

      currentMessageIndex = 0;
      setState(() {
        isLoading = false;
      });

      // Start stacking animation
      _stackAnimationController.forward();
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void nextMessage() {
    if (currentMessageIndex < allMessages.length - 1) {
      _paperAnimationController.forward().then((_) {
        setState(() {
          currentMessageIndex++;
        });
        _paperAnimationController.reverse();
      });
    }
  }

  void previousMessage() {
    if (currentMessageIndex > 0) {
      _paperAnimationController.forward().then((_) {
        setState(() {
          currentMessageIndex--;
        });
        _paperAnimationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // gradient: LinearGradient(
          //   begin: Alignment.topCenter,
          //   end: Alignment.bottomCenter,
          //   colors: [
          //     Color(0xFFF5E6D3), // Warm paper color
          //     Color(0xFFE8D4B0), // Aged paper color
          //   ],
          // ),
          image: DecorationImage(
            image: AssetImage("assets/images/bg.png"),
            fit: BoxFit.cover,
            opacity: 0.4,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background texture
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/bg.png"),
                    fit: BoxFit.cover,
                    opacity: 0.1,
                  ),
                ),
              ),

              if (isLoading) ...[
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Organizing your love letters...",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontFamily: 'Lobster',
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Column(
                  children: [
                    // Header with refresh and counter
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: loadAllMessages,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.refresh,
                                color: textColor,
                                size: 20,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (allMessages.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: textColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: textColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "${currentMessageIndex + 1} of ${allMessages.length}",
                                style: const TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Lobster',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Paper stack
                    Expanded(
                      child: allMessages.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    color: textColor,
                                    size: 64,
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "No love letters found",
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 20,
                                      fontFamily: 'Lobster',
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : AnimatedBuilder(
                              animation: _stackAnimationController,
                              builder: (context, child) {
                                return GestureDetector(
                                  onHorizontalDragEnd: (details) {
                                    if (details.primaryVelocity! > 300) {
                                      // Swipe right - previous message
                                      previousMessage();
                                    } else if (details.primaryVelocity! <
                                        -300) {
                                      // Swipe left - next message
                                      nextMessage();
                                    }
                                  },
                                  child: Center(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Stack of papers (background papers)
                                        for (int i = 0; i < 5; i++)
                                          Transform.translate(
                                            offset: Offset(
                                              i *
                                                  3.0 *
                                                  _stackAnimationController
                                                      .value,
                                              i *
                                                  -2.0 *
                                                  _stackAnimationController
                                                      .value,
                                            ),
                                            child: Transform.rotate(
                                              angle: (i * 0.02) *
                                                  _stackAnimationController
                                                      .value,
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.85,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.6,
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(
                                                          0.7 - (i * 0.1)),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius:
                                                          10 + (i * 2.0),
                                                      offset: Offset(
                                                          2 + i * 1.0,
                                                          4 + i * 1.0),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),

                                        // Current message paper (top paper)
                                        AnimatedBuilder(
                                          animation: _paperAnimationController,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale: 1.0 -
                                                  (_paperAnimationController
                                                          .value *
                                                      0.05),
                                              child: Transform.rotate(
                                                angle: _paperAnimationController
                                                        .value *
                                                    0.1,
                                                child: Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.85,
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.6,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.15),
                                                        blurRadius: 20,
                                                        offset:
                                                            const Offset(0, 8),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    child: Stack(
                                                      children: [
                                                        // Paper texture
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            gradient:
                                                                LinearGradient(
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                              colors: [
                                                                Colors.white,
                                                                Colors.grey
                                                                    .shade50,
                                                              ],
                                                            ),
                                                          ),
                                                        ),

                                                        // Content
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(30),
                                                          child: Column(
                                                            children: [
                                                              // Date header
                                                              Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 8,
                                                                ),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: textColor
                                                                      .withOpacity(
                                                                          0.1),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              20),
                                                                ),
                                                                child: Text(
                                                                  allMessages[
                                                                          currentMessageIndex]
                                                                      [
                                                                      'timeAgo']!,
                                                                  style:
                                                                      const TextStyle(
                                                                    color:
                                                                        textColor,
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontFamily:
                                                                        'Lobster',
                                                                  ),
                                                                ),
                                                              ),

                                                              const SizedBox(
                                                                  height: 30),

                                                              // Message content
                                                              Expanded(
                                                                child: Center(
                                                                  child:
                                                                      SingleChildScrollView(
                                                                    child: Text(
                                                                      allMessages[
                                                                              currentMessageIndex]
                                                                          [
                                                                          'message']!,
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            18,
                                                                        height:
                                                                            1.6,
                                                                        color: Colors
                                                                            .black87,
                                                                        fontFamily:
                                                                            'Georgia',
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),

                                                              const SizedBox(
                                                                  height: 20),

                                                              // Sender signature
                                                              const Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .favorite,
                                                                    color:
                                                                        textColor,
                                                                    size: 18,
                                                                  ),
                                                                  SizedBox(
                                                                      width: 8),
                                                                  Text(
                                                                    "With love, ${Env.partnerName}",
                                                                    style:
                                                                        TextStyle(
                                                                      color:
                                                                          textColor,
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontFamily:
                                                                          'Lobster',
                                                                      fontStyle:
                                                                          FontStyle
                                                                              .italic,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                      width: 8),
                                                                  Icon(
                                                                    Icons
                                                                        .favorite,
                                                                    color:
                                                                        textColor,
                                                                    size: 18,
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Navigation hints and controls
                    if (allMessages.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Swipe hint
                            Text(
                              "← Swipe to browse love letters →",
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),

                            const SizedBox(height: 15),

                            // Navigation buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Previous button
                                GestureDetector(
                                  onTap: currentMessageIndex > 0
                                      ? previousMessage
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: currentMessageIndex > 0
                                          ? textColor.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: currentMessageIndex > 0
                                            ? textColor.withOpacity(0.3)
                                            : Colors.grey.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.arrow_back_ios,
                                          color: currentMessageIndex > 0
                                              ? textColor
                                              : Colors.grey,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "Previous",
                                          style: TextStyle(
                                            color: currentMessageIndex > 0
                                                ? textColor
                                                : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Next button
                                GestureDetector(
                                  onTap: currentMessageIndex <
                                          allMessages.length - 1
                                      ? nextMessage
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: currentMessageIndex <
                                              allMessages.length - 1
                                          ? textColor.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: currentMessageIndex <
                                                allMessages.length - 1
                                            ? textColor.withOpacity(0.3)
                                            : Colors.grey.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Next",
                                          style: TextStyle(
                                            color: currentMessageIndex <
                                                    allMessages.length - 1
                                                ? textColor
                                                : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: currentMessageIndex <
                                                  allMessages.length - 1
                                              ? textColor
                                              : Colors.grey,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
