import 'package:fire_nex/presentation/cubit/complaint/complaint_cubit.dart';
import 'package:fire_nex/presentation/cubit/fire/fire_cubit.dart';
import 'package:fire_nex/presentation/cubit/intrusion/intru_cubit.dart';
import 'package:fire_nex/presentation/cubit/mappings/panel_sim_number_cubit.dart';
import 'package:fire_nex/presentation/cubit/mappings/site_cubit.dart';
import 'package:fire_nex/presentation/cubit/panel/panel_cubit.dart';
import 'package:fire_nex/presentation/cubit/user/user_cubit.dart';
import 'package:fire_nex/presentation/cubit/vendor/vendor_cubit.dart';
import 'package:fire_nex/presentation/screens/splash.dart';
import 'package:fire_nex/utils/app_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'constants/app_colors.dart';
import 'core/data/repo_impl/complaint_repo_impl.dart';
import 'core/data/repo_impl/fire_no_impl.dart';
import 'core/data/repo_impl/intru_no_impl.dart';
import 'core/data/repo_impl/panel_repository_impl.dart';
import 'core/data/repo_impl/user_repository_impl.dart';
import 'core/data/repo_impl/vendor_repo_impl.dart';
import 'data/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInfo.instance.init();

  final appDatabase = AppDatabase();

  runApp(
    const MyApp(),
    // MultiProvider(
    //   // providers: [
    //   //   // Database
    //   //   Provider<AppDatabase>.value(value: appDatabase),
    //   //
    //   //   // Repositories (all use the same db)
    //   //   Provider<UserRepository>(create: (_) => UserRepository(appDatabase)),
    //   //   ProxyProvider<AppDatabase, PanelRepository>(
    //   //     update: (_, db, __) => PanelRepository(db),
    //   //   ),
    //   //   ProxyProvider<AppDatabase, VendorRepository>(
    //   //     update: (_, db, __) => VendorRepository(db),
    //   //   ),
    //   //   ProxyProvider<AppDatabase, ComplaintRepository>(
    //   //     update: (_, db, __) => ComplaintRepository(db),
    //   //   ),
    //   //
    //   //   // View Models
    //   //   ProxyProvider<UserRepository, UserViewModel>(
    //   //     update: (_, repo, __) => UserViewModel(repo),
    //   //   ),
    //   //   ChangeNotifierProvider<PanelViewModel>(
    //   //     create:
    //   //         (context) => PanelViewModel(
    //   //           Provider.of<PanelRepository>(context, listen: false),
    //   //         ),
    //   //   ),
    //   //   ProxyProvider<VendorRepository, VendorViewModel>(
    //   //     update: (_, repo, __) => VendorViewModel(repo),
    //   //   ),
    //   //   ProxyProvider<ComplaintRepository, ComplaintViewModel>(
    //   //     update: (_, repo, __) => ComplaintViewModel(repo),
    //   //   ),
    //   // ],
    //   providers: [
    //     BlocProvider<UserCubit>(create: (_) => UserCubit(UserRepoImpl())),
    //     BlocProvider<PanelCubit>(
    //       create: (_) => PanelCubit(PanelRepositoryImpl()),
    //     ),
    //     BlocProvider<VendorCubit>(create: (_) => VendorCubit(VendorRepoImpl())),
    //     BlocProvider<FireCubit>(create: (_) => FireCubit(FireNoRepoImpl())),
    //     BlocProvider<IntruCubit>(create: (_) => IntruCubit(IntruNoRepoImpl())),
    //     BlocProvider<ComplaintCubit>(
    //       create: (_) => ComplaintCubit(ComplaintRepoImpl()),
    //     ),
    //     BlocProvider<SiteCubit>(create: (_) => SiteCubit()),
    //     BlocProvider<PanelSimNumberCubit>(create: (_) => PanelSimNumberCubit()),
    //   ],
    //   child: BlocProvider(
    //     create: (_) => LoginCubit(UserRepo()),
    //     child: const MyApp(),
    //   ),
    // ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.light();

    return MultiBlocProvider(
      providers: [
        BlocProvider<UserCubit>(create: (_) => UserCubit(UserRepoImpl())),
        BlocProvider<PanelCubit>(
          create: (_) => PanelCubit(PanelRepositoryImpl()),
        ),
        BlocProvider<VendorCubit>(create: (_) => VendorCubit(VendorRepoImpl())),
        BlocProvider<FireCubit>(create: (_) => FireCubit(FireNoRepoImpl())),
        BlocProvider<IntruCubit>(create: (_) => IntruCubit(IntruNoRepoImpl())),
        BlocProvider<ComplaintCubit>(
          create: (_) => ComplaintCubit(ComplaintRepoImpl()),
        ),
        BlocProvider<SiteCubit>(create: (_) => SiteCubit()),
        BlocProvider<PanelSimNumberCubit>(create: (_) => PanelSimNumberCubit()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FireNex',
        theme: ThemeData(
          // colorScheme: ColorScheme.fromSeed(seedColor: AppColors.colorPrimary),
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

          dropdownMenuTheme: DropdownMenuThemeData(
            textStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Colors.black,
            ),
          ),

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
      ),
    );
  }
}
