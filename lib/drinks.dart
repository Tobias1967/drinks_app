import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DrinkSelectionScreen(),
    );
  }
}

class DrinkSelectionScreen extends StatefulWidget {
  const DrinkSelectionScreen({super.key});

  @override
  _DrinkSelectionScreenState createState() => _DrinkSelectionScreenState();
}

class _DrinkSelectionScreenState extends State<DrinkSelectionScreen> {
  List<dynamic> drinks = [];
  bool filterWithoutPineapple = false;
  dynamic selectedDrink;

  @override
  void initState() {
    super.initState();
    loadDrinks();
  }

  Future<void> fetchDrinks() async {
    final response = await http.get(Uri.parse(
        'https://www.thecocktaildb.com/api/json/v1/1/search.php?f=a'));
    if (response.statusCode == 200) {
      final decodedData = json.decode(response.body);
      setState(() {
        drinks = decodedData['drinks'];
        selectedDrink = drinks.isNotEmpty ? drinks[0] : null;
      });
      saveDrinksToLocal(decodedData['drinks']);
    } else {
      throw Exception('Failed to load drinks');
    }
  }

  Future<void> loadDrinks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? drinksData = prefs.getString('drinks');
    if (drinksData != null) {
      setState(() {
        drinks = json.decode(drinksData);
        selectedDrink = drinks.isNotEmpty ? drinks[0] : null;
      });
    } else {
      fetchDrinks();
    }
  }

  Future<void> saveDrinksToLocal(List<dynamic> drinks) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('drinks', json.encode(drinks));
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredDrinks = filterWithoutPineapple
        ? drinks.where((drink) {
            return !drink.values.any((ingredient) =>
                ingredient != null &&
                ingredient.toString().toLowerCase().contains('pineapple'));
          }).toList()
        : drinks;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Getränke-Auswahl'),
      ),
      body: Column(
        children: [
          CheckboxListTile(
            title: const Text('Zeige Getränke ohne Ananas!'),
            selectedTileColor: Colors.red,
            value: filterWithoutPineapple,
            onChanged: (bool? value) {
              setState(() {
                filterWithoutPineapple = value ?? false;
                selectedDrink =
                    filteredDrinks.isNotEmpty ? filteredDrinks[0] : null;
              });
            },
          ),
          if (filteredDrinks.isNotEmpty)
            DropdownButton<dynamic>(
              iconSize: 50,
              value: selectedDrink,
              onChanged: (dynamic newValue) {
                setState(() {
                  selectedDrink = newValue;
                });
              },
              items: filteredDrinks
                  .map<DropdownMenuItem<dynamic>>((dynamic drink) {
                return DropdownMenuItem<dynamic>(
                  value: drink,
                  child: Text(drink['strDrink']),
                );
              }).toList(),
            ),
          if (selectedDrink != null)
            ListTile(
              leading: Image.network(
                selectedDrink['strDrinkThumb'],
                width: 200,
                height: 30,
              ),
              title: Text(selectedDrink['strDrink']),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DrinkDetailScreen(drink: selectedDrink),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class DrinkDetailScreen extends StatefulWidget {
  final dynamic drink;

  const DrinkDetailScreen({super.key, required this.drink});

  @override
  State<DrinkDetailScreen> createState() => _DrinkDetailScreenState();
}

class _DrinkDetailScreenState extends State<DrinkDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.drink['strDrink']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(widget.drink['strDrinkThumb']),
            const SizedBox(height: 16),
            const Text(
              'Ingredients:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            for (int i = 1; i <= 15; i++)
              if (widget.drink['strIngredient$i'] != null)
                Text(
                    '${widget.drink['strIngredient$i']} - ${widget.drink['strMeasure$i'] ?? ''}'),
            const SizedBox(height: 16),
            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(widget.drink['strInstructions']),
          ],
        ),
      ),
    );
  }
}
