import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'weather_service.dart';

void main() async {
  // Ensure environment variables are loaded before app starts
  await dotenv.load(fileName: ".env");
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Info App',
      theme: ThemeData.dark(),
      home: const WeatherScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  String errorMessage = '';

  final TextEditingController cityController = TextEditingController();

  /// Fetch weather for current location using geolocator
  Future<void> _getWeatherByLocation() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Request permission to access GPS
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception("Location permission denied.");
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition();
      final apiKey = dotenv.env['OPENWEATHER_API_KEY']!;
      final data = await WeatherService.fetchWeatherByCoords(position.latitude, position.longitude, apiKey);

      setState(() {
        weatherData = data;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  /// Fetch weather for entered city
  Future<void> _getWeatherByCity() async {
    final city = cityController.text.trim();
    if (city.isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final apiKey = dotenv.env['OPENWEATHER_API_KEY']!;
      final data = await WeatherService.fetchWeatherByCity(city, apiKey);

      setState(() {
        weatherData = data;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  /// Get appropriate weather icon based on condition
  String _getWeatherIcon(String condition) {
    if (condition.contains("cloud")) return "☁️";
    if (condition.contains("rain")) return "🌧️";
    if (condition.contains("clear")) return "☀️";
    if (condition.contains("snow")) return "❄️";
    return "🌈";
  }

  @override
  void initState() {
    super.initState();
    _getWeatherByLocation(); // Load location weather by default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _getWeatherByLocation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset("images/weather_bg.jpg", fit: BoxFit.cover),
            Container(color: Colors.black.withOpacity(0.5)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  const SizedBox(height: 60),
                  const Center(child: Text("🌦 Weather Info App", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 20),

                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityController,
                          decoration: const InputDecoration(
                            hintText: "Enter city name",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _getWeatherByCity,
                        icon: const Icon(Icons.search, size: 30),
                        color: Colors.white,
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Loading or Error
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (errorMessage.isNotEmpty)
                    Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
                  else if (weatherData != null)
                      _buildWeatherCard(),

                  const SizedBox(height: 20),

                  // Refresh Button
                  ElevatedButton.icon(
                    onPressed: _getWeatherByLocation,
                    icon: const Icon(Icons.gps_fixed),
                    label: const Text("Use Current Location"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a card widget to show weather info
  Widget _buildWeatherCard() {
    final temp = weatherData!['main']['temp'].toString();
    final humidity = weatherData!['main']['humidity'].toString();
    final wind = weatherData!['wind']['speed'].toString();
    final condition = weatherData!['weather'][0]['description'];

    return Card(
      color: Colors.white70,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(_getWeatherIcon(condition.toLowerCase()), style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 10),
            Text("Condition: $condition", style: const TextStyle(fontSize: 20)),
            Text("Temperature: $temp °C", style: const TextStyle(fontSize: 20)),
            Text("Humidity: $humidity %", style: const TextStyle(fontSize: 20)),
            Text("Wind Speed: $wind m/s", style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
