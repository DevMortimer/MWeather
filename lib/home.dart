import 'package:MWeather/api.dart';
import 'package:MWeather/filled_form_field.dart';
import 'package:MWeather/main.dart';
import 'package:MWeather/prompt.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:weather/weather.dart';

Future<String?> getMessageOfTheDay(Weather w) async {
  final model = GenerativeModel(
    model: 'gemini-pro',
    apiKey: apiKey,
    generationConfig: GenerationConfig(temperature: 0.4),
    safetySettings: [
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
    ],
  );
  final content = [Content.text(getPrompt(w))];
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
  bool reloading = false;
  late final Future<void> _updateWeatherFuture;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final location = prefs.getString('location');

      // if there is local data, then load it
      if (location != null && location.isNotEmpty) {
        setState(() {
          _location = location;
          message = null;
          weather = null;
        });
        _updateWeatherFuture = _updateLocation(context, _location!);
      }
    });
  }

  Future<void> _updateLocation(BuildContext context, String newLocation) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('location', newLocation);
      final weatherData = await wf.currentWeatherByCityName(newLocation);
      if (weatherData == null) {
        throw Exception('Failed to fetch weather data');
      }
      final String? MoD = await getMessageOfTheDay(weatherData);
      setState(() {
        reloading = false;
        weather = weatherData;
        _location = newLocation;
        message = MoD;
      });
    } catch (e) {
      if (context.canPop()) {
        context.pop();
      }
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              icon: const Icon(Icons.error),
              title: const Text("Error"),
              content: const Text("Error fetching weather data."),
              actions: [
                TextButton(
                  child: const Text("Return"),
                  onPressed: () {
                    context.pop();
                  },
                ),
              ],
            );
          });
      await _resetData(context);
    }
  }

  Future<void> _resetData(BuildContext context) async {
    context.loaderOverlay.show();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('location');
    setState(() {
      _location = null;
      weather = null;
      message = null;
    });
    context.loaderOverlay.hide();
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
              if (_location != null && _location != '') {
                setState(() {
                  message = null;
                  weather = null;
                  reloading = true;
                });

                await _updateLocation(
                  context,
                  _location!,
                );
              }
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
                        String location = locationController.text.trim();
                        setState(() {
                          _location = location;
                          reloading = true;
                        });
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
                      String location = locationController.text.trim();
                      setState(() {
                        _location = location;
                        reloading = true;
                      });
                      await _updateLocation(context, locationController.text);
                      locationController.clear();
                    },
                  ),
                ],
              ),
            )
          : FutureBuilder(
              future: weather == null &&
                      message == null &&
                      (_location != null && _location!.isNotEmpty)
                  ? _updateWeatherFuture
                  : null,
              builder: ((context, snapshot) {
                return Skeletonizer(
                  enabled: reloading ||
                      (snapshot.connectionState == ConnectionState.waiting ||
                          snapshot.connectionState == ConnectionState.active),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.sp, 16.sp, 16.sp, 0),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Image
                            Skeleton.keep(
                              child: Image.asset('assets/images/data.png',
                                  height: 32.h),
                            ),

                            // Title
                            Skeleton.keep(
                              child: Text(
                                "Weather Data",
                                style: theme.textTheme.displaySmall,
                              ),
                            ),
                            SizedBox(height: 1.h),

                            // Date snapshot
                            Text(
                              "Date snapshot: ${weather?.date?.toString() ?? "Unknown"}.",
                            ),
                            SizedBox(height: 1.h),

                            // Message
                            message != null ? Text(message!) : Container(),
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
                            SizedBox(height: 8.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
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
