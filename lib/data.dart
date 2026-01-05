import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'prediction_model.dart';

List<Prediction> defaultPredictions = [
  Prediction(text: "yes", color: Colors.green),
  Prediction(text: "no", color: Colors.red),
  Prediction(text: "maybe", color: Colors.orange),
  Prediction(text: "ask again later", color: Colors.blue),
  Prediction(text: "it is unclear", color: Colors.purple),
];

class PredictionConfig {
  String id;
  String title;
  List<Prediction> predictions;
  bool isDefault;

  PredictionConfig({
    required this.id,
    required this.title,
    required this.predictions,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'predictions': predictions.map((p) => p.toJson()).toList(),
        'isDefault': isDefault,
      };

  factory PredictionConfig.fromJson(Map<String, dynamic> json) {
    return PredictionConfig(
      id: json['id'],
      title: json['title'],
      predictions: (json['predictions'] as List)
          .map((p) => Prediction.fromJson(p))
          .toList(),
      isDefault: json['isDefault'] ?? false,
    );
  }
}

class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  bool isPremium = false;
  List<PredictionConfig> configs = [];
  String activeConfigId = 'default';

  PredictionConfig get activeConfig {
    return configs.firstWhere(
      (c) => c.id == activeConfigId,
      orElse: () => configs.firstWhere(
        (c) => c.isDefault,
        orElse: () => PredictionConfig(
          id: 'default',
          title: 'Classic 8-Ball',
          predictions: defaultPredictions,
          isDefault: true,
        ),
      ),
    );
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isPremium = prefs.getBool('isPremium') ?? false;
    activeConfigId = prefs.getString('activeConfigId') ?? 'default';

    final String? configsJson = prefs.getString('configs');
    if (configsJson != null) {
      try {
        List<dynamic> decoded = jsonDecode(configsJson);
        configs = decoded.map((d) => PredictionConfig.fromJson(d)).toList();
      } catch (e) {
        _initDefault();
      }
    } else {
      _initDefault();
    }
  }

  void _initDefault() {
    configs = [
      PredictionConfig(
        id: 'default',
        title: 'Classic 8-Ball',
        predictions: List.from(defaultPredictions),
        isDefault: true,
      ),
    ];
  }

  Future<void> setPremium(bool value) async {
    isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', value);
  }

  Future<void> setActiveConfig(String id) async {
    activeConfigId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeConfigId', activeConfigId);
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    String json = jsonEncode(configs.map((c) => c.toJson()).toList());
    await prefs.setString('configs', json);
    await prefs.setString('activeConfigId', activeConfigId);
  }
}
