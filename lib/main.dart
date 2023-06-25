import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  WeatherScreenState createState() => WeatherScreenState();
}

class WeatherScreenState extends State<WeatherScreen> {
  String apiKey = '67ef72ad0aff7190c78da578f01a0196';

  String location = 'Chicago';
  String temperature = '';
  String weatherDescription = '';
  String weatherIcon = '';
  String humidity = '';
  String searchLocation = '';

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  Future<void> fetchWeatherData() async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=$location&appid=$apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        temperature = data['main']['temp'].toString();
        weatherDescription = data['weather'][0]['description'];
        weatherIcon = data['weather'][0]['icon'];
        humidity = data['main']['humidity'].toString();
      });
    } else {
      if (kDebugMode) {
        print('Failed to load weather data');
      }
    }
  }

  Future<void> fetchWeatherDataForLocation(double latitude, double longitude) async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        temperature = data['main']['temp'].toString();
        weatherDescription = data['weather'][0]['description'];
        weatherIcon = data['weather'][0]['icon'];
        humidity = data['main']['humidity'].toString();
      });
    } else {
      if (kDebugMode) {
        print('Failed to load weather data');
      }
    }
  }

  Future<Map<String, dynamic>?> openLocationSelectionScreen() async {
    return await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
    );
  }

  Future<Map<String, dynamic>?> fetchWeatherDataForSearchLocation(String location) async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=$location&appid=$apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'name': data['name'],
        'temperature': data['main']['temp'],
        'longitude': data['coord']['lon'],
      };
    } else {
      if (kDebugMode) {
        print('Error al cargar los datos meteorológicos');
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F3057),
              Color(0xFF0F3057),
              Color(0xFF1A508B),
              Color(0xFF328CC1),
            ],
            stops: [0.1, 0.4, 0.7, 0.9],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Location: $location',
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'Temperature: $temperature°C',
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'Description: $weatherDescription',
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'Humidity: $humidity%',
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Image.network(
                'https://openweathermap.org/img/w/$weatherIcon.png',
                width: 200, height: 200,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final selectedLocation = await openLocationSelectionScreen();

                  if (selectedLocation != null) {
                    final temperature = selectedLocation['temperature'];
                    final longitude = selectedLocation['longitude'];

                    await fetchWeatherDataForLocation(temperature, longitude);
                    setState(() {
                      location = selectedLocation['name'];
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text(
                  'Selecione Ubicacion',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        onChanged: (value) {
                          searchLocation = value;
                        },
                        decoration: const InputDecoration(
                          hintText: 'Enter location',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final searchedLocation = await fetchWeatherDataForSearchLocation(searchLocation);

                      if (searchedLocation != null) {
                        final temperature = searchedLocation['temperature'];
                        final longitude = searchedLocation['longitude'];

                        await fetchWeatherDataForLocation(temperature, longitude);
                        setState(() {
                          location = searchedLocation['name'];
                          searchLocation = '';
                        });
                      } else {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Error'),
                              content: const Text('No se pudieron obtener los datos meteorológicos para la ubicación ingresada.'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text(
                      'Buscar',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LocationSelectionScreen extends StatelessWidget {
  const LocationSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elegir ubicacion'),
        backgroundColor: Colors.blue,
      ),
      body:  Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F3057),
              Color(0xFF0F3057),
              Color(0xFF1A508B),
              Color(0xFF328CC1),
            ],
            stops: [0.1, 0.4, 0.7, 0.9],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context, {'name': 'London', 'temperature': 51.5074, 'longitude': -0.1278}),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
                ),
                child: const Text(
                  'London',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, {'name': 'Paris', 'temperature': 48.8566, 'longitude': 2.3522}),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 30),
                ),
                child: const Text(
                  'Paris',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, {'name': 'New York', 'temperature': 40.7128, 'longitude': -74.0060}),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                ),
                child: const Text(
                  'New York',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
