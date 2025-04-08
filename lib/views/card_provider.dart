import 'package:flutter/material.dart';

enum SwipeStatus { none, like, dislike }

class CardProvider extends ChangeNotifier {
  int cardState = 0; // 0: Match Score, 1: Year, 2: Department
  bool isFlipped = false; // Tracks if the card is flipped
  bool isSwipingOut = false;
  bool isSwipingRightOut = false;

  // Added safety for position and angle
  Offset _position = Offset.zero;
  double _angle = 0;
  Size _screenSize = Size(1, 1); // Default to non-zero size

  // Safe getters to prevent NaN/infinite values
  Offset get position {
    if (_position.dx.isNaN ||
        _position.dx.isInfinite ||
        _position.dy.isNaN ||
        _position.dy.isInfinite) {
      return Offset.zero;
    }
    return _position;
  }

  double get angle {
    if (_angle.isNaN || _angle.isInfinite) {
      return 0.0;
    }
    return _angle;
  }

  void setScreenSize(Size screenSize) {
    if (screenSize.width > 0 && screenSize.height > 0) {
      _screenSize = screenSize;
    }
  }

  void triggerSwipeRightOut() {
    isSwipingRightOut = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      isSwipingRightOut = false;
      resetPosition();
      notifyListeners();
    });
  }

  void triggerExternalSwipeLeft() {
    isSwipingOut = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      isSwipingOut = false;
      resetPosition();
      notifyListeners();
    });
  }

  void flipCard() {
    isFlipped = !isFlipped;
    notifyListeners();
  }

  void nextState() {
    cardState = (cardState + 1) % 3;
    notifyListeners();
  }

  void startPosition(DragStartDetails details) {
    notifyListeners();
  }

  void updatePosition(DragUpdateDetails details) {
    // Update position safely
    final newDx = _position.dx + details.delta.dx;
    final newDy = _position.dy + details.delta.dy;

    // Safety check to prevent extreme values
    if (newDx.isFinite && newDy.isFinite) {
      _position = Offset(newDx, newDy);

      // Calculate angle safely - ensure screenSize width isn't zero
      if (_screenSize.width > 0) {
        final normalizedX = _position.dx / (_screenSize.width / 2);
        // Clamp angle to prevent extreme values (-15 to 15 degrees)
        _angle = 15 * normalizedX.clamp(-1.0, 1.0);
      }
    }

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

    // Safety check for screenSize
    if (_screenSize.width <= 0) return SwipeStatus.none;

    final delta = _screenSize.width / 4;

    if (x >= delta) {
      return SwipeStatus.like;
    } else if (x <= -delta) {
      return SwipeStatus.dislike;
    }

    return SwipeStatus.none;
  }
}
