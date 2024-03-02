import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:mweather/home.dart';

final routes = GoRouter(
  routes: [
    // Home Page
    GoRoute(
      path: "/",
      builder: (context, state) {
        return const LoaderOverlay(child: HomePage());
      },
    ),
  ],
);
