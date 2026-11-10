/// The request timed out; delivery may still complete on the server.
class LoginCodeDeliveryUncertainException implements Exception {
  const LoginCodeDeliveryUncertainException();

  @override
  String toString() => 'Login code delivery could not be confirmed';
}
