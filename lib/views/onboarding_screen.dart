import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({required this.onFinish, super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: "Meet SenseAI –\nYour Smart Emotion Assistant",
      description:
          "Understand, analyze, and explore your emotions through text, voice, images, and video. SenseAI brings your feelings into focus using cutting-edge AI.",
      imagePath: 'assets/onboarding1.png', // TODO: Replace with your image path
      buttonText: "Next",
    ),
    _OnboardingPageData(
      title: "Talk, Snap, or Record – We'll Sense It",
      description:
          "Whether it's your voice, a photo, or a video, SenseAI detects emotional tone, mood, and sentiment instantly—so you can reflect, respond, and grow.",
      imagePath: 'assets/onboarding2.png', // TODO: Replace with your image path
      buttonText: "Next",
    ),
    _OnboardingPageData(
      title: "Summarize &\nUnderstand Instantly",
      description:
          "Get instant emotional summaries and downloadable reports from every conversation, voice note, or visual cue. Your emotion log, one tap away.",
      imagePath: 'assets/onboarding3.png', // TODO: Replace with your image path
      buttonText: "Get Started",
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    // Save onboarding completion status
    prefs.setBool('hasSeenOnboarding', true);
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A3576), // Deep blue as in your image
      body: SafeArea(
        child: PageView.builder(
          controller: _controller,
          itemCount: _pages.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (context, i) {
            final page = _pages[i];
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24.0.w,
                vertical: 16.0.h,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 25.h),
                  Image.asset(
                    page.imagePath,
                    height: 220.h,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 25.h),
                  Text(
                    page.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 20.sp),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0A3576),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                      onPressed: _nextPage,
                      child: Text(
                        page.buttonText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String description;
  final String imagePath;
  final String buttonText;
  _OnboardingPageData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.buttonText,
  });
}
