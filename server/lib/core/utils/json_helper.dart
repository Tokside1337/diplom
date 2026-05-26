class JsonHelper {
  static Object? toJson(Object? item) {
    if (item is DateTime) return item.toIso8601String();
    return item;
  }
}
