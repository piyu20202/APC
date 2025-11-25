import 'package:flutter/foundation.dart';

typedef TabSwitchCallback = void Function(int index);

class NavigationService {
  NavigationService._();

  static final NavigationService instance = NavigationService._();

  TabSwitchCallback? _tabSwitchCallback;
  VoidCallback? _cartCountRefreshCallback;
  VoidCallback? _cartItemsRefreshCallback;

  void registerTabController(TabSwitchCallback callback) {
    _tabSwitchCallback = callback;
  }

  void switchToTab(int index) {
    _tabSwitchCallback?.call(index);
  }

  void registerCartCountRefresher(VoidCallback callback) {
    _cartCountRefreshCallback = callback;
  }

  void refreshCartCount() {
    _cartCountRefreshCallback?.call();
  }

  void registerCartItemsRefresher(VoidCallback callback) {
    _cartItemsRefreshCallback = callback;
  }

  void refreshCartItems() {
    _cartItemsRefreshCallback?.call();
  }
}

