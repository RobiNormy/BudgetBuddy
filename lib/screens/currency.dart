import 'package:flutter/material.dart';
import 'package:flutter_debouncer/flutter_debouncer.dart';
const duration = Duration(milliseconds: 300);
class Convertor extends StatefulWidget {
  const Convertor({super.key});
  @override
  State<Convertor> createState() => _ConvertorState();
}

class _ConvertorState extends State<Convertor> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFF0F1117),
        appBar: AppBar(
          title: Text("Currency"),
        ),

      ),
    );
  }
}
