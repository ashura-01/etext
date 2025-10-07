import 'package:flutter/material.dart';
import 'dart:async';

class ProgressButton extends StatefulWidget {
  final double size;
  final double strokeWidth; 
  final Color color;
  final VoidCallback onComplete; 

  const ProgressButton({
    super.key,
    this.size = 100,
    this.strokeWidth = 6,
    required this.color,
    required this.onComplete,
  });

  @override
  State<ProgressButton> createState() => _ProgressButtonState();
}

class _ProgressButtonState extends State<ProgressButton> {
  double progress = 0.0;
  Timer? timer;
  bool completed = false;

  void _startProgress() {
    timer?.cancel();
    completed = false;
    timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      setState(() {
        progress += 0.01;
        if (progress >= 1.0 && !completed) {
          progress = 1.0;
          completed = true;
          widget.onComplete();
          timer?.cancel();
        }
      });
    });
  }

  void _resetProgress() {
    timer?.cancel();
    setState(() {
      progress = 0.0;
      completed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double innerSize = widget.size - widget.strokeWidth * 2;

    return GestureDetector(
      onTapDown: (_) => _startProgress(),
      onTapUp: (_) => _resetProgress(),
      onTapCancel: () => _resetProgress(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: widget.strokeWidth,
              backgroundColor: Colors.blueGrey,
              valueColor: AlwaysStoppedAnimation<Color>(const Color.fromARGB(255, 0, 255, 242)),
            ),
          ),
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              'DELETE',
              style: TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}