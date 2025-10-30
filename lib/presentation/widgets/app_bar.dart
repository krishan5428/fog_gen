import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String pageName;
  final bool isFilter;
  final bool isDash;
  final VoidCallback? onBack;
  final VoidCallback? onFilterTap;
  final VoidCallback? onMoreTaps;
  final bool isProfile;

  const CustomAppBar({
    super.key,
    required this.pageName,
    required this.isFilter,
    this.isDash = true,
    this.onBack,
    this.onFilterTap,
    this.onMoreTaps,
    this.isProfile = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading:
          isDash
              ? null
              : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                color: AppColors.white,
                onPressed: onBack,
              ),
      iconTheme: const IconThemeData(
        color: AppColors.white,
      ),
      backgroundColor: Colors.grey,
      automaticallyImplyLeading: true,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.grey,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      title: Row(
        children: [
          Image.asset('assets/images/sec_logo.png', width: 120),
          const SizedBox(width: 10),
          Container(width: 1, height: 30, color: AppColors.colorAccent),
          const SizedBox(width: 10),
          Text(
            pageName,
            style: const TextStyle(fontSize: 14, color: AppColors.white),
          ),
        ],
      ),
      actions: [
        if (isFilter)
          IconButton(
            onPressed: onFilterTap,
            icon: const Icon(Icons.filter_list),
          ),
        if (isProfile)
          IconButton(
            onPressed: onMoreTaps,
            icon: const Icon(Icons.more_vert, color: AppColors.colorAccent),
          ),
      ],
    );
  }
}
