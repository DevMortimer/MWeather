import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:MWeather/routes.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

void main() {
  runApp(const MWeather());
}

class MWeather extends StatefulWidget {
  const MWeather({super.key});

  @override
  State<MWeather> createState() => _MWeatherState();
}

class _MWeatherState extends State<MWeather> {
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return ResponsiveSizer(
          builder: (BuildContext context, Orientation orientation,
              ScreenType screenType) {
            return MaterialApp.router(
              title: 'MWeather',
              theme: ThemeData(
                colorScheme: lightDynamic ??
                    ColorScheme.fromSeed(
                      brightness: Brightness.light,
                      seedColor: const Color(0xff884ba1),
                    ),
                useMaterial3: true,
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              darkTheme: ThemeData(
                colorScheme: darkDynamic ??
                    ColorScheme.fromSeed(
                      brightness: Brightness.dark,
                      seedColor: const Color(0xff884ba1),
                    ),
                useMaterial3: true,
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              themeMode: ThemeMode.system,
              routerConfig: routes,
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}
