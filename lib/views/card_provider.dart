import 'package:flutter/material.dart';

enum SwipeStatus { none, like, dislike }

class CardProvider extends ChangeNotifier {
  int cardState = 0; // 0: Match Score, 1: Year, 2: Department
  bool isFlipped = false; // Tracks if the card is flipped

  void flipCard() {
    isFlipped = !isFlipped;
    notifyListeners();
  }

  void nextState() {
    cardState = (cardState + 1) % 3;
    notifyListeners();
  }

  Offset _position = Offset.zero;
  double _angle = 0;
  Size _screenSize = Size.zero;

  Offset get position => _position;
  double get angle => _angle;

  void setScreenSize(Size screenSize) {
    _screenSize = screenSize;
  }

  void startPosition(DragStartDetails details) {
    notifyListeners();
  }

  void updatePosition(DragUpdateDetails details) {
    _position += details.delta;

    // Calculate angle based on horizontal movement
    final x = _position.dx;
    _angle = 15 * x / (_screenSize.width / 2);

    notifyListeners();
  }

  void endPosition() {
    notifyListeners();
  }

  void resetPosition() {
    _position = Offset.zero;
    _angle = 0;
    notifyListeners();
  }

  SwipeStatus getStatus() {
    final x = _position.dx;
    final delta = _screenSize.width / 4;

    if (x >= delta) {
      return SwipeStatus.like;
    } else if (x <= -delta) {
      return SwipeStatus.dislike;
    }

    return SwipeStatus.none;
  }
}
