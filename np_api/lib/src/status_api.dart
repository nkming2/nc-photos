part of 'api.dart';

@npLog
class ApiStatus {
  const ApiStatus(this.api);

  Future<Response> get() async {
    const endpoint = "status.php";
    try {
      return await api.request("GET", endpoint);
    } catch (e) {
      _log.severe("[get] Failed while get", e);
      rethrow;
    }
  }

  final Api api;
}
