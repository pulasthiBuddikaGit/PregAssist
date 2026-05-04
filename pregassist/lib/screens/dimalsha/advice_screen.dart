// dart:ui removed — all used elements are provided by flutter/material.dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AdviceScreen extends StatefulWidget {
  final List<String> adviceList;

  const AdviceScreen({super.key, required this.adviceList});

  @override
  State<AdviceScreen> createState() => _AdviceScreenState();
}

class _AdviceScreenState extends State<AdviceScreen> {
  final FlutterTts tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    setupVoice();
  }

  Future setupVoice() async {
    await tts.setLanguage("en-US");
    await tts.setPitch(1.1);
    await tts.setSpeechRate(0.45);

    // 🔥 IMPORTANT (fix speaking issue)
    await tts.awaitSpeakCompletion(true);

    // 🔥 Try female voice
    var voices = await tts.getVoices;
    for (var v in voices) {
      if (v.toString().toLowerCase().contains("female")) {
        await tts.setVoice(v);
        break;
      }
    }
  }

  Future speakAllAdvice() async {
    await tts.stop();

    // 🔥 Intro
    await tts.speak("Here is your personalized care advice.");

    for (String advice in widget.adviceList) {
      await tts.speak(advice); // now waits automatically
    }
  }

  @override
  void dispose() {
    tts.stop(); // stop when leaving screen
    super.dispose();
  }

  Widget buildImageSlider() {
    final List<Map<String, dynamic>> sliderData = [
      {
        "image": "https://images.unsplash.com/photo-1512295767273-ac109ac3acfa",
        "title": "Stay Hydrated",
        "subtitle": "Drink enough water for a healthy pregnancy.",
      },
      {
        "image": "https://images.unsplash.com/photo-1505751172876-fa1923c5c528",
        "title": "Monitor Your Vitals",
        "subtitle": "Track blood pressure, sugar and heart rate regularly.",
      },
      {
        "image": "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9",
        "title": "Healthy Daily Habits",
        "subtitle": "Eat balanced meals and get enough rest.",
      },
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: 190,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.92,
      ),
      items: sliderData.map((item) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(item["image"]?.toString() ?? "", fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item["title"]?.toString() ?? "",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(item["subtitle"]?.toString() ?? "",
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  bool isEmergencyAdvice(String advice) {
    final text = advice.toLowerCase();
    return text.contains("immediate") || text.contains("emergency");
  }

  bool isCautionAdvice(String advice) {
    final text = advice.toLowerCase();
    return text.contains("monitor") ||
        text.contains("high") ||
        text.contains("low");
  }

  Color cardTint(String advice) {
    if (isEmergencyAdvice(advice)) {
      return Colors.red.withOpacity(0.1);
    } else if (isCautionAdvice(advice)) {
      return Colors.orange.withOpacity(0.1);
    } else {
      return Colors.white.withOpacity(0.7);
    }
  }

  List<Color> iconGradient(String advice) {
    if (isEmergencyAdvice(advice)) {
      return [Colors.red, Colors.redAccent];
    } else if (isCautionAdvice(advice)) {
      return [Colors.orange, Colors.orangeAccent];
    } else {
      return [Colors.green, Colors.greenAccent];
    }
  }

  IconData adviceIcon(String advice) {
    if (isEmergencyAdvice(advice)) {
      return Icons.warning;
    } else if (isCautionAdvice(advice)) {
      return Icons.health_and_safety;
    } else {
      return Icons.check;
    }
  }

  Widget buildAdviceCard(String advice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardTint(advice),
        borderRadius: BorderRadius.circular(22),
      ),
      child: ListTile(
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: iconGradient(advice)),
          ),
          child: Icon(adviceIcon(advice), color: Colors.white),
        ),
        title: Text(
          advice,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2B80FF), Color(0xFFAC46FF)],
            ),
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(25)),
          ),
        ),
        title: const Text("Care Plan",
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.white),
            onPressed: speakAllAdvice,
          )
        ],
        leadingWidth: 90,
        leading: Row(
          children: [
            IconButton(
              icon:
                  const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Image.asset('assets/logo.png'),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDEEF4), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: widget.adviceList.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  buildImageSlider(),
                  const SizedBox(height: 24),
                  const Text(
                    "Personalized Care Recommendations",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Guidance based on your current maternal health inputs",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 18),
                ],
              );
            }

            return buildAdviceCard(widget.adviceList[index - 1]);
          },
        ),
      ),
    );
  }
}