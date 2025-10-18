import 'package:fire_nex/presentation/screens/splash.dart';
import 'package:fire_nex/presentation/viewModel/complaint_view_model.dart';
import 'package:fire_nex/presentation/viewModel/panel_view_model.dart';
import 'package:fire_nex/presentation/viewModel/user_view_model.dart';
import 'package:fire_nex/presentation/viewModel/vendor_view_model.dart';
import 'package:fire_nex/utils/app_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'constants/app_colors.dart';
import 'core/logic/cubits/login_cubit.dart';
import 'core/repo/user_repo.dart';
import 'data/database/app_database.dart';
import 'data/repositories/complaint_repo.dart';
import 'data/repositories/panel_repo.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/vendor_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInfo.instance.init();

  final appDatabase = AppDatabase();

  runApp(
    MultiProvider(
      providers: [
        // Database
        Provider<AppDatabase>.value(value: appDatabase),

        // Repositories (all use the same db)
        Provider<UserRepository>(create: (_) => UserRepository(appDatabase)),
        ProxyProvider<AppDatabase, PanelRepository>(
          update: (_, db, __) => PanelRepository(db),
        ),
        ProxyProvider<AppDatabase, VendorRepository>(
          update: (_, db, __) => VendorRepository(db),
        ),
        ProxyProvider<AppDatabase, ComplaintRepository>(
          update: (_, db, __) => ComplaintRepository(db),
        ),

        // View Models
        ProxyProvider<UserRepository, UserViewModel>(
          update: (_, repo, __) => UserViewModel(repo),
        ),
        ChangeNotifierProvider<PanelViewModel>(
          create:
              (context) => PanelViewModel(
                Provider.of<PanelRepository>(context, listen: false),
              ),
        ),
        ProxyProvider<VendorRepository, VendorViewModel>(
          update: (_, repo, __) => VendorViewModel(repo),
        ),
        ProxyProvider<ComplaintRepository, ComplaintViewModel>(
          update: (_, repo, __) => ComplaintViewModel(repo),
        ),
      ],
      child: BlocProvider(
        create: (_) => LoginCubit(UserRepo()),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.light();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FireNex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.colorPrimary),
        fontFamily: 'Montserrat',

        // Text styles
        textTheme: baseTheme.textTheme.copyWith(
          bodyLarge: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          bodySmall: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
        ),

        // AppBar
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),

        // Dropdown
        dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Colors.black,
          ),
        ),

        // Buttons
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
