import 'package:flutter/material.dart';
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
      titleSpacing: 0,
      toolbarHeight: kToolbarHeight,
      automaticallyImplyLeading: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.greyDark,
      iconTheme: const IconThemeData(
        color: AppColors.white, // This makes the hamburger icon white
      ),
      leading: isDash
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: onBack,
            ),
      title: Row(
        children: [
          Image.asset('assets/images/logo.png', width: 80, height: 40),
          const SizedBox(width: 10),
          Container(width: 1, height: 30, color: AppColors.white),
          const SizedBox(width: 10),
          Text(
            pageName,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
      actions: [
        // if (isFilter)
        //   IconButton(
        //     onPressed: onFilterTap,
        //     icon: const Icon(Icons.filter_list, color: AppColors.white),
        //   ),
        if (isProfile)
          IconButton(
            onPressed: onMoreTaps,
            icon: const Icon(Icons.more_vert, color: AppColors.white),
          ),
      ],
    );
  }
}
