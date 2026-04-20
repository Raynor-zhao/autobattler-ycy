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
  String _goldResult = '';
  String _turnResult = '';
  String _cardResult = '';
  bool _isProcessing = false;
  bool _isExperienceProcessing = false;
  bool _isGoldProcessing = false;
  bool _isTurnProcessing = false;
  bool _isCardProcessing = false;
  
  int _currentLevel = 1;
  int _currentExperience = 0;
  int _gold = 10;
  int _winStreak = 0;
  int _loseStreak = 0;
  String _lastBattleResult = '';
  
  Map<int, Map<String, int>> _cardPool = {};
  List<dynamic> _shopCards = [];
  List<dynamic> _benchCards = [];
  List<dynamic> _battlefieldCards = [];
  int _maxBenchSlots = 10;
  int _maxBattlefieldSlots = 1;
  
  List<List<dynamic?>> _playerBoard = List.generate(8, (_) => List<dynamic?>.filled(8, null));
  int _boardRows = 8;
  int _boardCols = 8;
  int _playerStartRow = 4;
  String? _selectedBenchCard;

  @override
  void initState() {
    super.initState();
    _fetchServerStatus();
    _fetchShop();
    _fetchBoard();
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

  Future<void> _fetchBoard() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/cards'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'get_board'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _playerBoard = List<List<dynamic?>>.from(
              (data['data']['playerBoard'] as List).map(
                (row) => List<dynamic?>.from(row.map((cell) => cell)),
              ),
            );
            _boardRows = data['data']['boardInfo']['rows'] ?? 8;
            _boardCols = data['data']['boardInfo']['cols'] ?? 8;
            _playerStartRow = 4;
          });
        }
      }
    } catch (e) {
      print('Error fetching board: $e');
    }
  }

  Future<void> _fetchShop() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/cards'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'get_shop'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _shopCards = List<dynamic>.from(data['data']['shopCards'] ?? []);
            _benchCards = List<dynamic>.from(data['data']['benchCards'] ?? []);
            _battlefieldCards = List<dynamic>.from(data['data']['battlefieldCards'] ?? []);
            _maxBenchSlots = data['data']['maxBenchSlots'] ?? 10;
            _maxBattlefieldSlots = data['data']['maxBattlefieldSlots'] ?? 1;
            _cardPool = Map<int, Map<String, int>>.from(
              (data['data']['cardPool'] as Map?)?.map(
                (key, value) => MapEntry(int.parse(key.toString()), Map<String, int>.from(value)),
              ) ?? {},
            );
          });
        }
      }
    } catch (e) {
      print('Error fetching shop: $e');
    }
  }

  Future<void> _processBattle() async {
    setState(() {
      _isProcessing = true;
      _battleResult = 'Processing...';
    });

    try {
      final battleData = {
        'units': _battlefieldCards.map((c) => {
          'id': c['id'],
          'name': c['name'],
          'power': (c['cost'] ?? 1) * 100 * (c['star'] ?? 1),
        }).toList()
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
Unit Count: ${result['unitCount']}
Result: ${result['battleResult']}
''';
            _lastBattleResult = result['battleResult'];
            
            if (result['battleResult'] == 'victory') {
              _winStreak++;
              _loseStreak = 0;
            } else if (result['battleResult'] == 'defeat') {
              _loseStreak++;
              _winStreak = 0;
            } else {
              _winStreak = 0;
              _loseStreak = 0;
            }
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
            _maxBattlefieldSlots = result['newLevel'];
            _experienceResult = '''
Experience Result:
New Level: ${result['newLevel']}
Experience: ${result['newExperience']}/${result['requiredExperience']}
Gold: ${result['newGold']}
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

  Future<void> _processGold() async {
    if (_lastBattleResult.isEmpty) {
      setState(() {
        _goldResult = 'No battle result to process!';
      });
      return;
    }

    setState(() {
      _isGoldProcessing = true;
      _goldResult = 'Processing...';
    });

    try {
      final goldData = {
        'currentGold': _gold,
        'battleResult': _lastBattleResult,
        'winStreak': _winStreak,
        'loseStreak': _loseStreak,
        'remainingGold': _gold
      };

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/gold'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(goldData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final result = data['data'];
          setState(() {
            _gold = result['newGold'];
            _goldResult = '''
Gold Result:
New Gold: ${result['newGold']}
Gold Gained: ${result['goldGained']}
Streak Bonus: ${result['streakBonus']}
Remaining Bonus: ${result['remainingBonus']}
''';
          });
        } else {
          setState(() {
            _goldResult = 'Error: ${data['error']}';
          });
        }
      } else {
        setState(() {
          _goldResult = 'Failed to process gold: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _goldResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isGoldProcessing = false;
      });
    }
  }

  Future<void> _processTurnStart() async {
    setState(() {
      _isTurnProcessing = true;
      _turnResult = 'Processing...';
    });

    try {
      final turnData = {
        'currentLevel': _currentLevel,
        'currentExperience': _currentExperience,
        'currentGold': _gold
      };

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/turn/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(turnData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final result = data['data'];
          setState(() {
            _currentLevel = result['newLevel'];
            _currentExperience = result['newExperience'];
            _gold = result['newGold'];
            _maxBattlefieldSlots = result['newLevel'];
            _turnResult = '''
Turn Start Result:
New Level: ${result['newLevel']}
Experience: ${result['newExperience']}/${result['requiredExperience']}
Gold: ${result['newGold']}
Experience Gained: ${result['experienceGained']}
Gold Gained: ${result['goldGained']}
''';
          });
        } else {
          setState(() {
            _turnResult = 'Error: ${data['error']}';
          });
        }
      } else {
        setState(() {
          _turnResult = 'Failed to process turn start: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _turnResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isTurnProcessing = false;
      });
    }
  }

  Future<void> _refreshShop() async {
    setState(() {
      _isCardProcessing = true;
      _cardResult = 'Refreshing shop...';
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/cards'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'refresh_shop', 'shopRefreshCost': 2}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _shopCards = List<dynamic>.from(data['data']['shopCards'] ?? []);
            _gold -= 2;
            _cardResult = 'Shop refreshed!';
          });
        } else {
          setState(() {
            _cardResult = 'Error: ${data['error']}';
          });
        }
      } else {
        setState(() {
          _cardResult = 'Failed to refresh shop';
        });
      }
    } catch (e) {
      setState(() {
        _cardResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isCardProcessing = false;
      });
    }
  }

  Future<void> _buyCard(String cardId, int cost) async {
    if (_gold < cost) {
      setState(() {
        _cardResult = 'Not enough gold!';
      });
      return;
    }

    if (_benchCards.length >= _maxBenchSlots) {
      setState(() {
        _cardResult = 'Bench is full!';
      });
      return;
    }

    setState(() {
      _isCardProcessing = true;
      _cardResult = 'Buying card...';
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/cards'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'buy',
          'cardId': cardId,
          'cardCost': cost,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _gold -= cost;
            _shopCards = List<dynamic>.from(data['data']['shopCards'] ?? []);
            _benchCards = List<dynamic>.from(data['data']['benchCards'] ?? []);
            _cardPool = Map<int, Map<String, int>>.from(
              (data['data']['cardPool'] as Map?)?.map(
                (key, value) => MapEntry(int.parse(key.toString()), Map<String, int>.from(value)),
              ) ?? {},
            );
            _cardResult = 'Card purchased!';
          });
        } else {
          setState(() {
            _cardResult = 'Error: ${data['error']}';
          });
        }
      } else {
        setState(() {
          _cardResult = 'Failed to buy card';
        });
      }
    } catch (e) {
      setState(() {
        _cardResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isCardProcessing = false;
      });
    }
  }

  Future<void> _placeCard(String cardId) async {
    if (_battlefieldCards.length >= _maxBattlefieldSlots) {
      setState(() {
        _cardResult = 'Battlefield is full! (Max: $_maxBattlefieldSlots)';
      });
      return;
    }

    setState(() {
      _isCardProcessing = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/cards'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'place_card',
          'cardId': cardId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _benchCards = List<dynamic>.from(data['data']['benchCards'] ?? []);
            _battlefieldCards = List<dynamic>.from(data['data']['battlefieldCards'] ?? []);
            _cardResult = 'Card placed to battlefield!';
          });
        } else {
          setState(() {
            _cardResult = 'Error: ${data['error']}';
          });
        }
      } else {
        setState(() {
          _cardResult = 'Failed to place card';
        });
      }
    } catch (e) {
      setState(() {
        _cardResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isCardProcessing = false;
      });
    }
  }

  Future<void> _returnCard(String cardId) async {
    if (_benchCards.length >= _maxBenchSlots) {
      setState(() {
        _cardResult = 'Bench is full!';
      });
      return;
    }

    setState(() {
      _isCardProcessing = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/cards'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'return_card',
          'cardId': cardId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _benchCards = List<dynamic>.from(data['data']['benchCards'] ?? []);
            _battlefieldCards = List<dynamic>.from(data['data']['battlefieldCards'] ?? []);
            _cardResult = 'Card returned to bench!';
          });
        } else {
          setState(() {
            _cardResult = 'Error: ${data['error']}';
          });
        }
      } else {
        setState(() {
          _cardResult = 'Failed to return card';
        });
      }
    } catch (e) {
      setState(() {
        _cardResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isCardProcessing = false;
      });
    }
  }

  Future<void> _placeOnBoard(String cardId, int row, int col) async {
    setState(() {
      _isCardProcessing = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/cards'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'place_on_board',
          'cardId': cardId,
          'row': row,
          'col': col,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _playerBoard = List<List<dynamic?>>.from(
              (data['data']['playerBoard'] as List).map(
                (row) => List<dynamic?>.from(row.map((cell) => cell)),
              ),
            );
            _benchCards = List<dynamic>.from(data['data']['benchCards'] ?? []);
            _selectedBenchCard = null;
            _cardResult = 'Card placed on board!';
          });
        } else {
          setState(() {
            _cardResult = 'Error: ${data['error']}';
          });
        }
      } else {
        setState(() {
          _cardResult = 'Failed to place card';
        });
      }
    } catch (e) {
      setState(() {
        _cardResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isCardProcessing = false;
      });
    }
  }

  Future<void> _removeFromBoard(int row, int col) async {
    setState(() {
      _isCardProcessing = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/cards'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'remove_from_board',
          'row': row,
          'col': col,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _playerBoard = List<List<dynamic?>>.from(
              (data['data']['playerBoard'] as List).map(
                (row) => List<dynamic?>.from(row.map((cell) => cell)),
              ),
            );
            _benchCards = List<dynamic>.from(data['data']['benchCards'] ?? []);
            _cardResult = 'Card removed from board!';
          });
        } else {
          setState(() {
            _cardResult = 'Error: ${data['error']}';
          });
        }
      } else {
        setState(() {
          _cardResult = 'Failed to remove card';
        });
      }
    } catch (e) {
      setState(() {
        _cardResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isCardProcessing = false;
      });
    }
  }

  void _onBenchCardTap(String cardId) {
    setState(() {
      if (_selectedBenchCard == cardId) {
        _selectedBenchCard = null;
      } else {
        _selectedBenchCard = cardId;
      }
    });
  }

  void _onBoardCellTap(int row, int col) {
    if (_selectedBenchCard != null) {
      if (row >= _playerStartRow && _playerBoard[row][col] == null) {
        _placeOnBoard(_selectedBenchCard, row, col);
      }
    } else {
      if (_playerBoard[row][col] != null) {
        _removeFromBoard(row, col);
      }
    }
  }

  Widget _buildChessBoard() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        children: [
          for (int row = 0; row < _boardRows; row++)
            Row(
              children: [
                for (int col = 0; col < _boardCols; col++)
                  GestureDetector(
                    onTap: () => _onBoardCellTap(row, col),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getCellColor(row, col),
                        border: Border.all(color: Colors.grey, width: 0.5),
                      ),
                      child: _playerBoard[row][col] != null
                          ? Center(
                              child: Text(
                                '${_playerBoard[row][col]['cost']}G',
                                style: const TextStyle(fontSize: 10),
                              ),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getCellColor(int row, int col) {
    if (row < _playerStartRow) {
      return Colors.grey[300]!;
    } else {
      return (row + col) % 2 == 0 ? Colors.white : Colors.green[100]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autobattler'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Server: $_serverMessage', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text('Gold: $_gold | Level: $_currentLevel | XP: $_currentExperience', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Win: $_winStreak | Lose: $_loseStreak', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            
            const Text('=== Shop ===', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var card in _shopCards)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text('${card['cost']}G ★${card['star'] ?? 1}'),
                        const SizedBox(height: 4),
                        ElevatedButton(
                          onPressed: _isCardProcessing ? null : () => _buyCard(card['id'], card['cost']),
                          child: const Text('Buy'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isCardProcessing ? null : _refreshShop,
              child: const Text('Refresh Shop (2G)'),
            ),
            const SizedBox(height: 16),
            
            Text('Bench (${_benchCards.length}/$_maxBenchSlots) - Tap to select', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var card in _benchCards)
                  GestureDetector(
                    onTap: () => _onBenchCardTap(card['id']),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedBenchCard == card['id'] ? Colors.purple : Colors.orange,
                          width: _selectedBenchCard == card['id'] ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: _selectedBenchCard == card['id'] ? Colors.purple[100] : null,
                      ),
                      child: Column(
                        children: [
                          Text('${card['cost']}G ★${card['star'] ?? 1}'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text('Battlefield (${_battlefieldCards.length}/$_maxBattlefieldSlots)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var card in _battlefieldCards)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text('${card['cost']}G ★${card['star'] ?? 1}'),
                        const SizedBox(height: 4),
                        ElevatedButton(
                          onPressed: _isCardProcessing ? null : () => _returnCard(card['id']),
                          child: const Text('Return'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text('Chess Board (8x8)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildChessBoard(),
            const SizedBox(height: 8),
            Text(_selectedBenchCard != null ? 'Tap empty cell (rows 4-7) to place card' : 'Tap card on board to remove', 
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            
            Text(_cardResult, style: TextStyle(fontSize: 16, color: Colors.red[700])),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processBattle,
                    child: _isProcessing ? const CircularProgressIndicator() : const Text('Battle'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isTurnProcessing ? null : _processTurnStart,
                    child: const Text('Start Turn'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isGoldProcessing ? null : _processGold,
                    child: const Text('Gold Reward'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _fetchShop,
                    child: const Text('Refresh'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(_battleResult, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(_turnResult, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(_goldResult, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
