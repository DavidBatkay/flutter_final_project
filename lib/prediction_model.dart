import 'package:flutter/material.dart';

class Prediction {
  String text;
  Color color;

  Prediction({required this.text, this.color = Colors.blue});

  Map<String, dynamic> toJson() => {
    'text': text,
    'color': color.value,
  };

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      text: json['text'],
      color: Color(json['color']),
    );
  }
}
