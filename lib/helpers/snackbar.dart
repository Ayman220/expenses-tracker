import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showSuccessMessage(String title, String message) {
  Get.snackbar(
    title,
    message,
    backgroundColor: Colors.green.shade600,
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
    borderRadius: 12,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    duration: const Duration(seconds: 3),
  );
}

void showErrorMessage(String title, String message) {
  Get.snackbar(
    title,
    message,
    backgroundColor: Colors.red.shade600,
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
    borderRadius: 12,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    duration: const Duration(seconds: 40),
  );
}

void showInfoMessage(String title, String message) {
  Get.snackbar(
    title,
    message,
    backgroundColor: Colors.blue.shade600,
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
    borderRadius: 12,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    duration: const Duration(seconds: 3),
  );
}
