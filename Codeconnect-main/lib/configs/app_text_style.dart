import 'package:flutter/material.dart';
import 'package:nitd_code/configs/app_colors.dart';

class AppTextStyle {
  AppTextStyle._();

  static TextStyle regularTextStyle = const TextStyle(
    color: AppColors.darkBlueColor,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    // fontFamily: 'Poppins',
  );

  static TextStyle semiBoldTestStyle = const TextStyle(
    color: AppColors.darkBlueColor,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    // fontFamily: "Poppins",
  );

  static TextStyle boldTextStyle = const TextStyle(
    color: AppColors.darkBlueColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    // fontFamily: "Poppins",
  );
}
