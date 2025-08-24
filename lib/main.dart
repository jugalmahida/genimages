import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:genimages/core/routes/routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:genimages/core/utils/app_bloc_observer.dart';
import 'package:genimages/di/injection_container.dart';
import 'package:genimages/domain/repositories/image_repository.dart';
import 'package:genimages/presentation/home/bloc/image_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    throw Exception('Error loading .env file: $e'); // Print error if any
  }

  // Bloc Observer
  Bloc.observer = AppBlocObserver();
  setupDependencies();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ImageBloc>(
      create: (_) => ImageBloc(getIt<ImageRepository>()),
      child: MaterialApp(
        title: "GenImages",
        themeMode: ThemeMode.system,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
