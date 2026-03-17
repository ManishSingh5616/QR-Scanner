enum QRType { url, wifi, contact, text }

class QRUtils {
  static QRType detectType(String data) {
    if (data.startsWith("http")) {
      return QRType.url;
    } else if (data.startsWith("WIFI:")) {
      return QRType.wifi;
    } else if (data.contains("BEGIN:VCARD")) {
      return QRType.contact;
    } else {
      return QRType.text;
    }
  }

  static Map<String, String> parseWifi(String data) {
    final result = <String, String>{};

    final cleaned = data.replaceAll("WIFI:", "").replaceAll(";", "\n");
    final lines = cleaned.split("\n");

    for (var line in lines) {
      if (line.startsWith("S:")) result["ssid"] = line.substring(2);
      if (line.startsWith("P:")) result["password"] = line.substring(2);
      if (line.startsWith("T:")) result["type"] = line.substring(2);
    }

    return result;
  }

  static String parseVCardName(String data) {
    final lines = data.split("\n");
    for (var line in lines) {
      if (line.startsWith("FN:")) {
        return line.substring(3);
      }
    }
    return "Unknown";
  }
}