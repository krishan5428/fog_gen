import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../core/repo/user_repo.dart';
import '../presentation/screens/splash.dart';
import '../presentation/cubit/user/user_cubit.dart';
import '../presentation/cubit/panel/panel_cubit.dart';
import '../presentation/cubit/vendor/vendor_cubit.dart';
import '../presentation/cubit/mappings/site_cubit.dart';
import '../presentation/cubit/mappings/panel_sim_number_cubit.dart';
import '../core/data/repo_impl/user_repository_impl.dart';
import '../core/data/repo_impl/panel_repository_impl.dart';
import '../core/data/repo_impl/vendor_repo_impl.dart';

import 'app_theme.dart';

class FogShieldApp extends StatelessWidget {
  const FogShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [Provider<UserRepo>(create: (_) => UserRepoImpl())],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<UserCubit>(
            create: (context) => UserCubit(context.read<UserRepo>()),
          ),
          BlocProvider<PanelCubit>(
            create: (_) => PanelCubit(PanelRepositoryImpl()),
          ),
          BlocProvider<VendorCubit>(
            create: (_) => VendorCubit(VendorRepoImpl()),
          ),
          BlocProvider<SiteCubit>(create: (_) => SiteCubit()),
          BlocProvider<PanelSimNumberCubit>(
            create: (_) => PanelSimNumberCubit(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FogShield',
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
