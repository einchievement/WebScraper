class Validator {

  static bool validatePageNumber(String? pageNumber) {
    if (isEmpty(pageNumber)) {
      return true;
    }
    int? number = int.tryParse(pageNumber!);
    return isNotNull(number);
  }

  static bool validateURL(String? url) {
    if (isEmpty(url)) {
      return false;
    }
    Uri? uri = Uri.tryParse(url!);
    return isNotNull(uri);
  }

  static bool isEmpty(String? s) {
    return s == null || s.isEmpty ? true : false;
  }

  static bool isNotNull(Object? o) {
    return o != null ? true : false;
  }
}
