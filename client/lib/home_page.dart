import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _serverMessage = 'Loading...';
  String _battleResult = '';
  String _experienceResult = '';
  bool _isProcessing = false;
  bool _isExperienceProcessing = false;
  
  // Experience system state
  int _currentLevel = 1;
  int _currentExperience = 0;
  int _gold = 10;

  @override
  void initState() {
    super.initState();
    _fetchServerStatus();
  }

  Future<void> _fetchServerStatus() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _serverMessage = data['message'];
        });
      } else {
        setState(() {
          _serverMessage = 'Failed to connect to server';
        });
      }
    } catch (e) {
      setState(() {
        _serverMessage = 'Error: $e';
      });
    }
  }

  Future<void> _processBattle() async {
    setState(() {
      _isProcessing = true;
      _battleResult = 'Processing...';
    });

    try {
      // Sample battle data
      final battleData = {
        'units': [
          {'id': 1, 'name': 'Knight', 'power': 250},
          {'id': 2, 'name': 'Archer', 'power': 180},
          {'id': 3, 'name': 'Mage', 'power': 320},
          {'id': 4, 'name': 'Tank', 'power': 400},
        ]
      };

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/process'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(battleData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final result = data['data'];
          setState(() {
            _battleResult = '''
Battle Result:
Total Power: ${result['totalPower']}
Average Power: ${result['averagePower'].toStringAsFixed(2)}
Unit Count: ${result['unitCount']}
Result: ${result['battleResult']}
''';
          });
        } else {
          setState(() {
            _battleResult = 'Error: ${data['error']}';
          });
        }
      } else {
        setState(() {
          _battleResult = 'Failed to process battle: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _battleResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processExperience(String action) async {
    if (_currentLevel >= 10) {
      setState(() {
        _experienceResult = 'Already at max level!';
      });
      return;
    }

    setState(() {
      _isExperienceProcessing = true;
      _experienceResult = 'Processing...';
    });

    try {
      final experienceData = {
        'currentLevel': _currentLevel,
        'currentExperience': _currentExperience,
        'action': action,
        'gold': _gold
      };

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/experience'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(experienceData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final result = data['data'];
          setState(() {
            _currentLevel = result['newLevel'];
            _currentExperience = result['newExperience'];
            _gold = result['newGold'];
            _experienceResult = '''
Experience Result:
New Level: ${result['newLevel']}
Experience: ${result['newExperience']}/${result['requiredExperience']}
Gold: ${result['newGold']}
Experience Gained: ${result['experienceGained']}
Gold Spent: ${result['goldSpent']}
${result['levelUps'] > 0 ? 'Level Ups: ${result['levelUps']}' : ''}
''';
          });
        } else {
          setState(() {
            _experienceResult = 'Error: ${data['error']}';
          });
        }
      } else {
        setState(() {
          _experienceResult = 'Failed to process experience: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _experienceResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isExperienceProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autobattler'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Server Status:',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              _serverMessage,
              style: TextStyle(fontSize: 16, color: Colors.blue),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _fetchServerStatus,
              child: const Text('Check Server Status'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Battle Processing:',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              _battleResult,
              style: TextStyle(fontSize: 16, color: Colors.green),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : _processBattle,
              child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('Process Battle'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Experience System:',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              'Level: $_currentLevel',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Experience: $_currentExperience',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Gold: $_gold',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              _experienceResult,
              style: TextStyle(fontSize: 16, color: Colors.orange),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isExperienceProcessing ? null : () => _processExperience('start_turn'),
                  child: const Text('Start Turn'),
                ),
                ElevatedButton(
                  onPressed: _isExperienceProcessing ? null : () => _processExperience('buy_experience'),
                  child: const Text('Buy Experience (4G)'),
                ),
                ElevatedButton(
                  onPressed: _isExperienceProcessing ? null : () => _processExperience('battle_reward'),
                  child: const Text('Battle Reward (2G)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}