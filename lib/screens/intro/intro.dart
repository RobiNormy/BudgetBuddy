import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  static String id = "intro_screen";

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _controller = PageController();
  bool onLastPage = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                onLastPage = (index == 3);
              });
            },
            children: [
              _buildPage(
                context,
                image: "images/nobg.png",
                title: "Welcome to BudgetBuddy",
                subtitle:
                "Track how you spend and add a budget of your money",
              ),
              _buildPage(
                context,
                image: "images/intro1.png",
                title: "Log in in seconds",
                subtitle:
                    "Experience the fastest way to track your daily spending without the hassle.",
              ),
              _buildPage(
                context,
                image: "images/intro2.png",
                title: "SET SMART BUDGETS",
                subtitle:
                    "Set limits for food, shopping, or fun and get alerted before you overspend.",
              ),
              _buildPage(
                context,
                image: 'images/intro3.png',
                title: "TAKE FULL CONTROL",
                subtitle:
                    "Your data is synced to the cloud safely. Your wallet, your rules.",
              ),
            ],
          ),
          Container(
            alignment: Alignment(0, 0.85),
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _controller.jumpTo(2),
                  child: Text(
                    "SKIP",
                    style: TextStyle(
                      color: theme.primaryColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                SmoothPageIndicator(
                  controller: _controller,
                  count: 4,
                  effect: ExpandingDotsEffect(
                    activeDotColor: theme.primaryColor,
                    dotColor: Colors.grey.withValues(alpha: 0.3),
                    dotHeight: 10,
                    dotWidth: 10,
                    expansionFactor: 3,
                  ),
                ),
                onLastPage
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('hasSeen', true);
                          if (!mounted) return;
                          Navigator.pushReplacementNamed(context, 'auth_gate');
                        },
                        child: const Text(
                          "DONE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: () => _controller.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeIn,
                        ),
                        icon: Icon(
                          Icons.arrow_forward_rounded,
                          color: theme.primaryColor,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildPage(
  BuildContext context, {
  required String image,
  required String title,
  required String subtitle,
}) {
  return Padding(
    padding: const EdgeInsets.all(40.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          image,
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.35,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 50),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
        ),
      ],
    ),
  );
}
