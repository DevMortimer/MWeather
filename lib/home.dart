import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:mweather/filled_form_field.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:weather/weather.dart';

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

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _location = (prefs.getString('location') ?? '');
    });
  }

  Future<void> _updateLocation(BuildContext context, String newLocation) async {
    context.loaderOverlay.show();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('location', newLocation);
      final weatherData = await wf.currentWeatherByCityName(newLocation);
      if (weatherData == null) {
        throw Exception('Failed to fetch weather data');
      }
      setState(() {
        weather = weatherData;
        _location = newLocation;
      });
    } catch (e) {
      print("Error fetching weather data: $e");
    } finally {
      context.loaderOverlay.hide();
    }
  }

  Future<void> _resetData(BuildContext context) async {
    context.loaderOverlay.show();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('location', '');
    setState(() {
      _location = null;
      weather = null;
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
                child: Column(
                  children: [
                    Text("Date is ${weather!.date.toString()}."),
                    Text("Country is ${weather!.country}."),
                    Text("Cloudiness is ${weather!.cloudiness}."),
                    Text("Temp is ${weather!.temperature?.celsius} celsius."),
                    Text("Pressure is ${weather!.pressure}."),
                    Text("Overall weather: ${weather!.weatherDescription}."),
                  ],
                ),
              ),
            ),
    );
  }
}
