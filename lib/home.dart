import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:mweather/api.dart';
import 'package:mweather/filled_form_field.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:weather/weather.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

Future<String?> getMessageOfTheDay(Weather w) async {
  final model = GenerativeModel(
    model: 'gemini-pro',
    apiKey: apiKey,
    generationConfig: GenerationConfig(temperature: 0.7),
    safetySettings: [
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
    ],
  );
  final prompt = 'You\'re a very informative and thoughtful forecaster.'
      'You are talking to an audience of various backgrounds.'
      'With these data, give brief tips, reminders, and message about the day:'
      '\" date: ${w.date} country_and_area: ${w.country} ${w.areaName} overall: ${w.weatherDescription} '
      'cloudiness: ${w.cloudiness} temperature: ${w.temperature} windspeed: ${w.windSpeed}'
      'wind_weather_condition_code: ${w.weatherConditionCode}\". Ignore blank or nonsensical data.'
      'Make your response ONLY be a 1-2 paragraph message. '
      'Theme of your message is the internet meme "gigachad" and "sigma male". '
      'Be slightly funny, but not too tryhard.'
      'Never mention the word "gigachad", "alpha", "chad", and "sigma male" in any shape or form.';
  final content = [Content.text(prompt)];
  final response = await model.generateContent(content);
  return response.text;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  WeatherFactory wf = WeatherFactory("c2e1af0df1f4d89bc494f20876a74652");
  String? _location;
  TextEditingController locationController = TextEditingController(text: "");
  Weather? weather;
  String? message;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() {
      weather = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final location = (prefs.getString('location') ?? '');
      if (location != null || location != '') {
        setState(() {
          _location = 'temp';
        });

        await prefs.setString('location', location);
        final weatherData = await wf.currentWeatherByCityName(location);
        if (weatherData == null) {
          throw Exception('Failed to fetch weather data');
        }
        final String? MoD = await getMessageOfTheDay(weatherData);

        setState(() {
          weather = weatherData;
          _location = location;
          message = MoD;
        });
      }
    } catch (e) {
      //
    }
  }

  Future<void> _updateLocation(BuildContext context, String newLocation) async {
    setState(() {
      _location = 'temp';
      weather = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('location', newLocation);
      final weatherData = await wf.currentWeatherByCityName(newLocation);
      if (weatherData == null) {
        throw Exception('Failed to fetch weather data');
      }
      final String? MoD = await getMessageOfTheDay(weatherData);
      setState(() {
        weather = weatherData;
        _location = newLocation;
        message = MoD;
      });
    } catch (e) {
      print("Error fetching weather data: $e");
    }
  }

  Future<void> _resetData(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('location', '');
    setState(() {
      _location = null;
      weather = null;
      message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("MWeather", style: theme.textTheme.headlineLarge),
        actions: [
          // Reload data
          IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await _updateLocation(
                context,
                (prefs.getString('location') ?? ''),
              );
            },
          ),

          // Clear data
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () async {
              await _resetData(context);
            },
          ),
        ],
      ),
      body: _location == '' || _location == null
          ? SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Welcome image
                  Image.asset('assets/images/welcome.png', height: 40.h),

                  // Text
                  Text(
                    "Welcome!",
                    style: GoogleFonts.getFont(
                      "Gloria Hallelujah",
                      textStyle: theme.textTheme.displayMedium,
                    ),
                  ),
                  SizedBox(height: 1.h),

                  // Location Text Field
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25.w),
                    child: FilledFormField(
                      locationController: locationController,
                      prefixIcon: const Icon(Icons.location_city),
                      helperText: "e.g. Manila, Philippines",
                      labelText: "Location",
                      onSubmit: (val) async {
                        await _updateLocation(context, val);
                        locationController.clear();
                      },
                    ),
                  ),
                  SizedBox(height: 1.h),

                  // Confirm
                  FloatingActionButton(
                    child: const Icon(Icons.check),
                    onPressed: () async {
                      await _updateLocation(context, locationController.text);
                      locationController.clear();
                    },
                  ),
                ],
              ),
            )
          : Skeletonizer(
              enabled: weather == null,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.sp, 16.sp, 16.sp, 0),
                  child: Column(
                    children: [
                      // Image
                      Image.asset('assets/images/data.png', height: 32.h),

                      // Title
                      Text(
                        "Weather Data",
                        style: theme.textTheme.displaySmall,
                      ),
                      SizedBox(height: 1.h),

                      // Date snapshot
                      Text(
                        "Date snapshot: ${weather?.date?.toString() ?? "Unknown"}.",
                      ),
                      SizedBox(height: 1.h),

                      // Area
                      weatherCard(context, const Icon(Icons.map), "Area",
                          weather?.areaName ?? "Unknown"),

                      // Overall weather
                      weatherCard(
                          context,
                          const Icon(Icons.note_alt),
                          "Overall",
                          weather?.weatherDescription?.toUpperCase() ??
                              "Unknown"),

                      // Temperature
                      weatherCard(
                        context,
                        const Icon(Icons.thermostat),
                        "Temperature",
                        '${weather?.temperature.toString()}; ${weather?.tempMin.toString()} to ${weather?.tempMax.toString()}' ??
                            "Unknown",
                      ),

                      // Wind speed
                      weatherCard(
                          context,
                          const Icon(Icons.wind_power),
                          "Wind Speed",
                          '${weather?.windSpeed} m/s' ?? "Unknown"),
                      SizedBox(height: 2.h),

                      // Message
                      message != null ? Text(message!) : Container(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

Widget weatherCard(
    BuildContext context, Icon icon, String label, String value) {
  return Card(
    margin: EdgeInsets.all(8.sp),
    child: Padding(
      padding: EdgeInsets.all(12.sp),
      child: Row(
        children: [
          icon,
          SizedBox(width: 2.w),
          Text(
            "$label:",
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(width: 2.w),
          Text(value),
        ],
      ),
    ),
  );
}
