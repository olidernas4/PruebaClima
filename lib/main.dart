import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

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

  List<ForecastData> forecastDataList = [];

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
    fetchForecastData();
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
  //llamado api
  Future<void> fetchForecastData() async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/data/2.5/forecast?q=$location&appid=$apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> forecastList = data['list'];
       //estado busqueda
      setState(() {
        forecastDataList = forecastList.map((forecast) {
          final DateTime date = DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000, isUtc: true);
          final double maxTemperature = forecast['main']['temp_max'].toDouble();
          final double minTemperature = forecast['main']['temp_min'].toDouble();
          final String description = forecast['weather'][0]['description'];
          final String icon = forecast['weather'][0]['icon'];

          return ForecastData(
            date: date,
            maxTemperature: maxTemperature,
            minTemperature: minTemperature,
            description: description,
            icon: icon,
          );
        }).toList();
      });
    } else {
      if (kDebugMode) {
        print('No se pudieron cargar los datos de pronóstico');
      }
    }
  }
//selecion de pagina
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
      return jsonDecode(response.body);
    } else {
      if (kDebugMode) {
        print('No se pudieron cargar los datos meteorológicos para la ubicación de búsqueda');
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplicación del tiempo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                final Map<String, dynamic>? result = await openLocationSelectionScreen();
                if (result != null && result.containsKey('location')) {
                  setState(() {
                    location = result['location'];
                  });
                  fetchWeatherData();
                  fetchForecastData();
                }
              },
              child: const Text('Cambio de locacion'),
            ),
            const SizedBox(height: 5),
            Text(
              'Clima actual es $location',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            if (temperature.isNotEmpty)
              Text(
                '$temperature°C',
                style: const TextStyle(fontSize: 30),
              ),
            if (weatherDescription.isNotEmpty)
              Text(
                weatherDescription,
                style: const TextStyle(fontSize: 24),
              ),
            if (weatherIcon.isNotEmpty)
              Image.network(
                'https://openweathermap.org/img/w/$weatherIcon.png',
                width: 100,
                height: 100,
              ),
            const SizedBox(height: 10),
            if (humidity.isNotEmpty)
              Text(
                'Humidity: $humidity%',
                style: const TextStyle(fontSize: 20),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final Map<String, dynamic>? result = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Buscar ubicación'),
                    content: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchLocation = value;
                        });
                      },
                      decoration: const InputDecoration(hintText: 'Enter a location'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final Map<String, dynamic>? weatherData =
                          await fetchWeatherDataForSearchLocation(searchLocation);
                          Navigator.pop(context, weatherData);
                        },
                        child: const Text('Buscar'),
                      ),
                    ],
                  ),
                );
                if (result != null && result.containsKey('name')) {
                  setState(() {
                    location = result['name'];
                  });
                  fetchWeatherData();
                  fetchForecastData();
                }
              },
              child: const Text('buscar ubicacion '),
            ),
            const SizedBox(height: 32),
            const Text(
              'Pronóstico extendido',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFB3E5FC),
                      Color(0xFFB3E5FC),
                      Color(0xFF328CC1),
                      Color(0xFF328CC1),

                    ],

                  ),
                ),
                child: ListView.builder(
                  itemCount: forecastDataList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final forecastData = forecastDataList[index];
                    final String date = forecastData.date.toString().substring(0, 10);
                    final String maxTemperature = forecastData.maxTemperature.toStringAsFixed(1);
                    final String minTemperature = forecastData.minTemperature.toStringAsFixed(1);
                    final String description = forecastData.description;
                    final String icon = forecastData.icon;

                    return ListTile(
                      leading: Image.network('https://openweathermap.org/img/w/$icon.png'),
                      title: Text(date),
                      subtitle: Text('Max: $maxTemperature°C  Min: $minTemperature°C\n$description'),
                    );
                  },
                ),
              ),
            ),
          ],
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
        title: const Text('Selecione ubicacion'),
      ),
      body:Container(
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
              const  SizedBox(height: 20),
               ElevatedButton(
                onPressed: () => Navigator.pop(context, {'name': 'Colombia', 'temperature': 40.7128, 'longitude': -74.0060}),
                 style: ElevatedButton.styleFrom(
               backgroundColor: Colors.blueAccent,
                 padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
               ),
               child: const Text(
               'Colombia',
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


class ForecastData {
  final DateTime date;
  final double maxTemperature;
  final double minTemperature;
  final String description;
  final String icon;

  ForecastData({
    required this.date,
    required this.maxTemperature,
    required this.minTemperature,
    required this.description,
    required this.icon,
  });
}
