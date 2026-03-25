class SocketConfig {
  static const String socketUrl = String.fromEnvironment(
    "SOCKET_URL",
    defaultValue: "http://localhost:3005",
  );

  static const String bannerUpdate = "banner:update";
  static const String tokenUpdate = "token:update";
}
