import 'package:flutter/material.dart';

class ChannelInputWidget extends StatelessWidget {
  final String label;
  final String hintText;
  final String initialValue;
  final Function(String) onChanged;
  final TextInputType keyboardType;
  const ChannelInputWidget({
    super.key,
    this.label = "",
    this.hintText = "",
    this.initialValue = "",
    required this.onChanged,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 600),
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        children: [
          Container(
            width: 60,
            child: Text(label + ":", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                hintText.isNotEmpty
                    ? Container(
                        margin: EdgeInsets.only(bottom: 3),
                        child: Text(hintText, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                      )
                    : Container(),
                Container(
                  constraints: BoxConstraints(minHeight: 30, maxHeight: 80, minWidth: 100, maxWidth: 550),
                  child: TextField(
                    minLines: 1,
                    maxLines: null,
                    style: TextStyle(fontSize: 12),
                    keyboardType: keyboardType,
                    controller: TextEditingController(text: initialValue),
                    decoration: InputDecoration(
                      fillColor: Colors.grey.shade100,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade200),
                        gapPadding: 0,
                      ),
                      border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade200)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      filled: true,
                      isDense: true,
                    ),
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
