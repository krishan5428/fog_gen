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
  final List<Widget>?
  extraActions; // Added to support custom actions like Network Badge

  const CustomAppBar({
    super.key,
    required this.pageName,
    required this.isFilter,
    required this.isDash,
    this.onBack,
    this.onFilterTap,
    this.onMoreTaps,
    this.isProfile = false,
    this.extraActions, // Added constructor parameter
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: AppColors.colorPrimary,
      elevation: 0,
      centerTitle: false, // Ensure title stays left aligned
      automaticallyImplyLeading: false,

      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark, // iOS
      ),

      leading: isDash
          ? IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menu',
            )
          : IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: onBack ?? () => Navigator.pop(context),
              color: Colors.white,
              tooltip: 'Back',
            ),
      title: Row(
        mainAxisSize: MainAxisSize.min, // Wrap content
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 70,
            height: 35,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 25, color: Colors.white24),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              pageName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),

      actions: [
        // if (isFilter)
        //   IconButton(
        //     onPressed: onFilterTap,
        //     icon: const Icon(Icons.filter_list, color: Colors.white),
        //     tooltip: 'Filter',
        //   ),
        if (isProfile)
          IconButton(
            onPressed: onMoreTaps,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            tooltip: 'More',
          ),
        // Insert extra actions here (like the network badge)
        if (extraActions != null) ...extraActions!,
      ],
    );
  }
}
