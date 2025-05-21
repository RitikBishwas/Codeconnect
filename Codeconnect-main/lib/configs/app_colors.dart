import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  ///MATERIAL COLOR
  static MaterialColor primarySwatchColor = MaterialColor(
    primaryColor.value,
    const <int, Color>{
      50: primaryColor,
      100: primaryColor,
      200: primaryColor,
      300: primaryColor,
      400: primaryColor,
      500: primaryColor,
      600: primaryColor,
      700: primaryColor,
      800: primaryColor,
      900: primaryColor,
    },
  );

  static const Color whiteColor = Colors.white;
  static const Color blackColor = Colors.black;
  static const Color redColor = Colors.red;
  static const Color greenColor = Colors.green;
  static const Color transparentColor = Colors.transparent;

  ///COLOR CODES
  static const Color primaryColor = Color(0xff790087);
  static const Color darkBlueColor = Color(0xff060757);
  static const Color scaffoldBackgroundColor = Color(0xffF8FAFF);
  static const Color lightGreyColor = Color(0xffe0e2ee);
  static const Color greyColor = Color(0xffD9D9D9);
  static const Color darkGreyColor = Color.fromARGB(255, 215, 215, 215);
  static const Color borderColor = Color(0xffE1E2EF);
  static const Color headerColor = Color(0xff2F2F2F);
  static const Color inactiveButtonColor = Color(0xffD3D4E3);
  static const Color lightBlueColor = Color(0xff52D3FF);
  static const Color creamColor = Color(0xffFCB35B);
  static const Color yellowColor = Color(0xffFC8800);
  static const Color toastColor = Color(0xff2a2928);
  static const Color borderGreenColor = Color(0xff22c55e);
  static const Color borderGreyColor = Color(0xffD6D6D6);
  static const Color textGreyColor = Color(0xff4F4F4F);
  static const Color profileTextColor = Color(0xffD3D4E3);
  static const Color lightPurpleColor = Color(0xffE4D8FF);
  static const Color addressCardColor = Color(0xffF5F5F5);
  static const Color selectedIconColor = Color(0xff173A8A);
  static const Color peachColor = Color(0xffEA7764);
  static const Color lightPeachColor = Color(0xffFFECE6);
  static const Color limeColor = Color(0xffE5F6C9);
  static const Color shadowGreenColor = Color(0xff7EA374);
  static const Color cardGreenColor = Color(0xffBDE6A4);
  static const Color darkGreenColor = Color(0xff3B761F);
  static const Color switchTrackColor = Color(0xff9BC08A);
  static const Color cardBlueColor = Color(0xffD9F4FD);
  static const Color cardRoseColor = Color(0xffFFE7EB);
  static const Color shadowRoseColor = Color(0xffF3BAC4);
  static const Color shadowBlueColor = Color(0xff8DCDDB);
  static const Color textDarkGreyColor = Color(0xff575757);
  static const Color prepareCardColor = Color(0xffF1F1F1);
  static const Color lockedCardColor = Color(0xff848484);
  static const Color filterBorderColor = Color(0xffB4B4B4);
  static const Color filterItemColor = Color(0xffE2ECFF);
  static const Color bookmarkCardColor = Color(0xfff4f4f4);
  static const Color careerCardBorderColor = Color(0xff462353);
  static const Color careerCardHandleColor = Color(0xff6B6B6B);
  static const Color blueColor = Color(0xff0043F0);
  static const Color buttonGradient1Color = Color(0xff212173);
  static const Color borderDarkGreyColor = Color(0xffb3b3b3);
  static const Color loginColor = Color.fromRGBO(53, 15, 101, 1);

  static LinearGradient purpleLinearGradient1 = const LinearGradient(
      colors: [Color(0xff562C8B), buttonGradient1Color],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight);
  static LinearGradient purpleLinearGradient2 = const LinearGradient(
      colors: [Color(0xff8446D2), buttonGradient1Color],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight);
  static LinearGradient careerCardGradient = const LinearGradient(
      colors: [Color(0xffF4F0F8), Color(0xffE8E8FF)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight);

  static LinearGradient disableCardGradient = const LinearGradient(colors: [
    Color.fromARGB(255, 33, 33, 33),
    Color.fromARGB(255, 54, 54, 60)
  ], begin: Alignment.centerLeft, end: Alignment.centerRight);
}
