import 'package:flutter/material.dart';

class AnimatedChip extends StatefulWidget {
  @override
  _AnimatedChipState createState() => _AnimatedChipState();
}

class _AnimatedChipState extends State<AnimatedChip>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _color;

  @override
  void initState() {
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    _color = ColorTween(begin: Colors.blue, end: Colors.blue[100])
        .animate(_animationController);
    _animationController.forward(from: 0.0);
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _animationController,
        builder: (BuildContext context, Widget? child) {
          return Chip(label: Text("xxx"), backgroundColor: _color.value);
        });
  }
}
