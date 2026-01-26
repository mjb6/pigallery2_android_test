import 'package:flutter/material.dart';

void showErrorSnackbar(String error, BuildContext context) {
  SnackBar snackBar = SnackBar(
    action: SnackBarAction(
      label: "OK",
      onPressed: () {},
    ),
    content: Text(error),
    duration: const Duration(days: 365),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
