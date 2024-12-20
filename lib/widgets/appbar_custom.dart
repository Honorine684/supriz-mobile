import 'package:flutter/material.dart';
import 'package:supriz/consts/colors.dart';
import '../consts/images.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    const String backgroundImage = appbarImg;
    precacheImage(const AssetImage(backgroundImage), context);

    return AppBar(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      centerTitle: true,
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: blueColor,
          ),
          Image.asset(
            backgroundImage,
            fit: BoxFit.cover,
          ),
        ],
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
