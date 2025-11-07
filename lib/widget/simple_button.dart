import 'package:flutter/material.dart';

///@Author jsji
///@Date 2025/3/5
///
///@Description

class SimpleButton extends StatelessWidget {
  const SimpleButton(this.label, this.onPressed,
      {super.key,
      this.backgroundColor = Colors.blue,
      this.fontColor = Colors.white,
      this.fontSize = 14,
      this.width,
      this.height});

  final String label;
  final Color backgroundColor;
  final Color fontColor;
  final double fontSize;
  final double? width;
  final double? height;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {
            //note 点击
            onPressed.call();
          },
          child: Container(
            height: height ?? 45,
            width: width,
            constraints: const BoxConstraints(maxWidth: 300, minWidth: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: Colors.blue), 
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Text(
                label,
                style: TextStyle(fontSize: fontSize, color: fontColor),
              ),
            ),
          ),
        ));
  }
}
