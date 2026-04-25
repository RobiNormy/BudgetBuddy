import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TutorialService {
  static List<TargetFocus> createHomeTargets({
    required GlobalKey balanceKey,
    required GlobalKey budgetKey,
    required GlobalKey analyticsKey,
    required GlobalKey topUpKey,
    required GlobalKey expenseKey,
  }) {
    List<TargetFocus> targets = [];

    targets.add(
      TargetFocus(
        identify: "balance",
        keyTarget: balanceKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTutorialContent(
                title: "Your Wallet",
                description: "This is your total balance. You can see your money and total expenses here at a glance.",
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "budget",
        keyTarget: budgetKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTutorialContent(
                title: "Budget Health",
                description: "Track your spending limits here. We'll let you know if you're on track or overspending.",
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "analytics",
        keyTarget: analyticsKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialContent(
                title: "Spending Analytics",
                description: "Visualize your spending patterns over time with our interactive charts.",
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "topup",
        keyTarget: topUpKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialContent(
                title: "Top Up",
                description: "Receive money or increase your balance? Tap here to add funds to your wallet.",
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "expense",
        keyTarget: expenseKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialContent(
                title: "Add Expense",
                description: "Spent some money? Quickly record your expenses here to stay organized.",
              );
            },
          ),
        ],
      ),
    );

    return targets;
  }

  static Widget _buildTutorialContent({
    required String title,
    required String description,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 24.0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.0,
          ),
        ),
      ],
    );
  }
}
