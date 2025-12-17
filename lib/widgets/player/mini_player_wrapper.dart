import 'package:anymex/widgets/player/mini_player.dart';
import 'package:flutter/material.dart';

class MiniPlayerWrapper extends StatelessWidget {
  final Widget child;
  
  const MiniPlayerWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const MiniPlayer(),
      ],
    );
  }
}
