import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class AdviceScreen extends StatelessWidget {
  final List<String> adviceList;
  const AdviceScreen({super.key, required this.adviceList});

  Widget buildImageSlider() {
    final List<Map<String, String>> sliderData = [
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
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
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
                Image.network(
                  item["image"]!,
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.62),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["title"]!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item["subtitle"]!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
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
    return text.contains("emergency") ||
        text.contains("immediately") ||
        text.contains("seek medical attention") ||
        text.contains("consult your doctor immediately");
  }

  bool isCautionAdvice(String advice) {
    final text = advice.toLowerCase();
    return text.contains("high bp") ||
        text.contains("low blood pressure") ||
        text.contains("high heart rate") ||
        text.contains("elevated blood sugar") ||
        text.contains("fever") ||
        text.contains("low body temperature") ||
        text.contains("consult your doctor") ||
        text.contains("monitor");
  }

  Color cardTint(String advice) {
    if (isEmergencyAdvice(advice)) {
      return Colors.red.withOpacity(0.10);
    } else if (isCautionAdvice(advice)) {
      return Colors.orange.withOpacity(0.10);
    } else {
      return Colors.white.withOpacity(0.70);
    }
  }

  Color borderTint(String advice) {
    if (isEmergencyAdvice(advice)) {
      return Colors.red.withOpacity(0.30);
    } else if (isCautionAdvice(advice)) {
      return Colors.orange.withOpacity(0.25);
    } else {
      return Colors.white.withOpacity(0.55);
    }
  }

  List<Color> iconGradient(String advice) {
    if (isEmergencyAdvice(advice)) {
      return [const Color(0xFFFF5A5F), const Color(0xFFFF8A80)];
    } else if (isCautionAdvice(advice)) {
      return [const Color(0xFFFFA726), const Color(0xFFFFCC80)];
    } else {
      return [const Color(0xFF4CAF50), const Color(0xFF81C784)];
    }
  }

  IconData adviceIcon(String advice) {
    if (isEmergencyAdvice(advice)) {
      return Icons.warning_amber_rounded;
    } else if (isCautionAdvice(advice)) {
      return Icons.health_and_safety_rounded;
    } else {
      return Icons.check_rounded;
    }
  }

  Widget buildAdviceCard(String advice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardTint(advice),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderTint(advice),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: iconGradient(advice),
                ),
                boxShadow: [
                  BoxShadow(
                    color: iconGradient(advice).first.withOpacity(0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                adviceIcon(advice),
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Text(
              advice,
              style: const TextStyle(
                fontSize: 17,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2A32),
              ),
            ),
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2B80FF), Color(0xFFAC46FF)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
          ),
        ),
        title: const Text(
          "Care Plan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 90,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40),
            ),
            Expanded(
              child: Image.asset('assets/logo.png', fit: BoxFit.contain),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDEEF4), Colors.white],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: adviceList.length + 1,
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
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2A32),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Guidance based on your current maternal health inputs",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              );
            }

            final advice = adviceList[index - 1];
            return buildAdviceCard(advice);
          },
        ),
      ),
    );
  }
}