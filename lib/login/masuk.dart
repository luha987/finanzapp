import 'package:flutter/material.dart';

class MasukHalaman extends StatelessWidget{
  final VoidCallback onTab;
  final String text;
  
  const MasukHalaman({
    super.key,
    required this.onTab,
    required this.text
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTab,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            color: Colors.blue,
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}