import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../presentation/screens/splash.dart';
import '../presentation/cubit/user/user_cubit.dart';
import '../presentation/cubit/panel/panel_cubit.dart';
import '../presentation/cubit/vendor/vendor_cubit.dart';
import '../presentation/cubit/fire/fire_cubit.dart';
import '../presentation/cubit/intrusion/intru_cubit.dart';
import '../presentation/cubit/complaint/complaint_cubit.dart';
import '../presentation/cubit/mappings/site_cubit.dart';
import '../presentation/cubit/mappings/panel_sim_number_cubit.dart';

import '../core/data/repo_impl/user_repository_impl.dart';
import '../core/data/repo_impl/panel_repository_impl.dart';
import '../core/data/repo_impl/vendor_repo_impl.dart';
import '../core/data/repo_impl/fire_no_impl.dart';
import '../core/data/repo_impl/intru_no_impl.dart';
import '../core/data/repo_impl/complaint_repo_impl.dart';

import 'app_theme.dart';

class FogShieldApp extends StatelessWidget {
  const FogShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => UserCubit(UserRepoImpl())),
        BlocProvider(create: (_) => PanelCubit(PanelRepositoryImpl())),
        BlocProvider(create: (_) => VendorCubit(VendorRepoImpl())),
        BlocProvider(create: (_) => FireCubit(FireNoRepoImpl())),
        BlocProvider(create: (_) => IntruCubit(IntruNoRepoImpl())),
        BlocProvider(create: (_) => ComplaintCubit(ComplaintRepoImpl())),
        BlocProvider(create: (_) => SiteCubit()),
        BlocProvider(create: (_) => PanelSimNumberCubit()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FogShield',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
