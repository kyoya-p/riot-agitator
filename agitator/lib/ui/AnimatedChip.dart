import 'package:flutter/material.dart';

class AnimatedChip extends StatefulWidget {
  AnimatedChipState createState() => AnimatedChipState();
}

class AnimatedChipState extends State<AnimatedChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _color;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );
    _color = ColorTween(
      begin: Colors.orange,
      end: Colors.orange[100],
    ).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _color,
      builder: (context, child) {
        return Chip(
          label: Text("xxx"),
          backgroundColor: _color.value,
        );
      },
    );
  }
}
