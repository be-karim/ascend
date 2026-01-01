import 'package:flutter_riverpod/flutter_riverpod.dart';

// Modern Riverpod 3.0 Implementation
class NavIndexNotifier extends Notifier<int> {
  @override
  int build() {
    return 0; // Initial Tab Index (HUD)
  }

  void setIndex(int index) {
    state = index;
  }
}

final navIndexProvider = NotifierProvider<NavIndexNotifier, int>(NavIndexNotifier.new);