class SupportVuidPrefix {
  static bool supportVuidPrefix(String vuid) {
    if (vuid == null || vuid.isEmpty) {
      return true;
    }
    RegExp exp = RegExp(r'^[a-zA-Z]{1,}\d{7,}.*[a-zA-Z]$');
    bool isVirtualId = exp.hasMatch(vuid);
    if (isVirtualId == true) {
      if (vuid.toUpperCase().startsWith("YC") ) {
        return false;
      }
    }
    return true;
  }
}
