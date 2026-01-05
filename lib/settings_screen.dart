import 'package:flutter/material.dart';
import 'data.dart';
import 'prediction_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isPremium = DataManager().isPremium;

    return Scaffold(
      appBar: AppBar(
        title: Text(isPremium ? 'My Oracles' : 'Upgrade to Pro'),
        actions: [
          if (isPremium)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () async {
                await DataManager().setPremium(false);
                setState(() {});
              },
            ),
        ],
      ),
      body: isPremium ? _buildConfigList() : _buildPaywall(),
      floatingActionButton: isPremium
          ? FloatingActionButton(
              onPressed: () => _openEditor(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildPaywall() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.diamond, size: 80, color: Colors.amber),
            const SizedBox(height: 20),
            const Text(
              "Unlock Cosmic Powers",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Create your own custom 8-ball configurations, colors, and answers!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () async {
                // Simulate Google Play purchase
                await DataManager().setPremium(true);
                setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Welcome to Pro!")),
                  );
                }
              },
              child: const Text(
                "Upgrade to Pro - \$4.99",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigList() {
    final configs = DataManager().configs;
    return ListView.builder(
      itemCount: configs.length,
      itemBuilder: (context, index) {
        final config = configs[index];
        final isActive = config.id == DataManager().activeConfigId;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isActive ? Colors.deepPurple.withOpacity(0.3) : null,
          child: ListTile(
            title: Text(
              config.title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.deepPurpleAccent : Colors.white,
              ),
            ),
            subtitle: Text("${config.predictions.length} responses"),
            trailing: isActive
                ? const Icon(Icons.check_circle, color: Colors.deepPurpleAccent)
                : null,
            onTap: () => _openEditor(config: config),
          ),
        );
      },
    );
  }

  void _openEditor({PredictionConfig? config}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConfigEditorScreen(config: config),
      ),
    );
    setState(() {}); // Refresh list on return
  }
}

class ConfigEditorScreen extends StatefulWidget {
  final PredictionConfig? config;
  const ConfigEditorScreen({super.key, this.config});

  @override
  State<ConfigEditorScreen> createState() => _ConfigEditorScreenState();
}

class _ConfigEditorScreenState extends State<ConfigEditorScreen> {
  late TextEditingController _titleController;
  late List<Prediction> _predictions;
  late String _configId;
  bool _isDefault = false;

  final List<Color> _colorOptions = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.config != null) {
      _titleController = TextEditingController(text: widget.config!.title);
      _predictions = List.from(widget.config!.predictions);
      _configId = widget.config!.id;
      _isDefault = widget.config!.isDefault;
    } else {
      _titleController = TextEditingController(text: "New Oracle");
      _predictions = [];
      _configId = DateTime.now().millisecondsSinceEpoch.toString();
      _isDefault = false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _saveAndSet() async {
    if (_titleController.text.isEmpty) return;
    if (_predictions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add at least one prediction!")),
      );
      return;
    }

    final newConfig = PredictionConfig(
      id: _configId,
      title: _titleController.text,
      predictions: _predictions,
      isDefault: _isDefault,
    );

    final manager = DataManager();
    final index = manager.configs.indexWhere((c) => c.id == _configId);
    if (index >= 0) {
      manager.configs[index] = newConfig;
    } else {
      manager.configs.add(newConfig);
    }

    await manager.setActiveConfig(_configId);
    await manager.saveData();

    if (mounted) Navigator.of(context).pop();
  }

  void _deleteConfig() async {
    if (_isDefault) return;
    DataManager().configs.removeWhere((c) => c.id == _configId);
    if (DataManager().activeConfigId == _configId) {
      await DataManager().setActiveConfig('default');
    }
    await DataManager().saveData();
    if (mounted) Navigator.of(context).pop();
  }

  void _addPrediction() {
    setState(() {
      _predictions.add(Prediction(text: "New Answer", color: Colors.blue));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isDefault ? 'View Oracle' : 'Edit Oracle'),
        actions: [
          if (!_isDefault)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteConfig,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _titleController,
              readOnly: _isDefault,
              decoration: const InputDecoration(
                labelText: 'Oracle Title',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: TextEditingController(
                                  text: _predictions[index].text,
                                )..selection = TextSelection.collapsed(
                                    offset: _predictions[index].text.length,
                                  ),
                                readOnly: _isDefault,
                                onChanged: (val) =>
                                    _predictions[index].text = val,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            if (!_isDefault)
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () => setState(
                                  () => _predictions.removeAt(index),
                                ),
                              ),
                          ],
                        ),
                        if (!_isDefault)
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: _colorOptions.map((color) {
                                return GestureDetector(
                                  onTap: () => setState(
                                    () => _predictions[index].color = color,
                                  ),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: _predictions[index].color == color
                                          ? Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (!_isDefault)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _addPrediction,
                      child: const Text("Add Answer"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveAndSet,
                      child: const Text("Set Active"),
                    ),
                  ),
                ],
              ),
            ),
          if (_isDefault)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await DataManager().setActiveConfig(_configId);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text("Set Active"),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
