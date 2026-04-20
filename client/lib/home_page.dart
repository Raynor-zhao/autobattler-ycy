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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autobattler'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Server Status:',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(
              _serverMessage,
              style: TextStyle(fontSize: 16, color: Colors.blue),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchServerStatus,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}