import 'package:flutter/cupertino.dart';

const Map<String, IconData> categoryIconMap = {
  'cart': CupertinoIcons.cart_fill,
  'shopping_cart': CupertinoIcons.cart_fill,
  'cart_fill': CupertinoIcons.cart_fill,
  'home': CupertinoIcons.house_fill,
  'house_fill': CupertinoIcons.house_fill,
  'car_fill': CupertinoIcons.car_fill,
  'directions_car': CupertinoIcons.car_fill,
  'bolt_fill': CupertinoIcons.bolt_fill,
  'heart_fill': CupertinoIcons.heart_fill,
  'local_hospital': CupertinoIcons.heart_fill,
  'music_note': CupertinoIcons.music_note,
  'movie': CupertinoIcons.film,
  'gift_fill': CupertinoIcons.gift_fill,
  'card_giftcard': CupertinoIcons.gift_fill,
  'briefcase_fill': CupertinoIcons.briefcase_fill,
  'doc_fill': CupertinoIcons.doc_fill,
  'airplane': CupertinoIcons.airplane,
  'sportscourt_fill': CupertinoIcons.sportscourt_fill,
  'money_dollar_circle_fill': CupertinoIcons.money_dollar_circle_fill,
  'money': CupertinoIcons.money_dollar_circle_fill,
  'account_balance': CupertinoIcons.money_dollar_circle_fill,
  'creditcard_fill': CupertinoIcons.creditcard_fill,
  'book_fill': CupertinoIcons.book_fill,
  'school': CupertinoIcons.book_fill,
  'person_fill': CupertinoIcons.person_fill,
  'checkroom': CupertinoIcons.person_fill,
  'flame_fill': CupertinoIcons.flame_fill,
  'receipt_long': CupertinoIcons.doc_text_fill,
  'laptop': CupertinoIcons.device_laptop,
  'trending_up': CupertinoIcons.graph_square_fill,
  'more_horiz': CupertinoIcons.ellipsis,
  'download': CupertinoIcons.arrow_down_circle_fill,
  'smile': CupertinoIcons.smiley_fill,
  'chart_bar_alt_fill': CupertinoIcons.chart_bar_alt_fill,
};

IconData getCategoryIcon(String? iconName) {
  if (iconName == null) return CupertinoIcons.tag_fill;
  return categoryIconMap[iconName] ?? CupertinoIcons.tag_fill;
}
