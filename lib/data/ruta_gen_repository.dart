import 'models.dart';

abstract interface class RutaGenRepository {
  Future<Customer> getCustomer();

  Future<List<Reward>> getRewards();

  Future<List<Movement>> getMovements({
    int page = 1,
    int limit = 20,
  });

  Future<List<Station>> getStations();

  // Se conserva para no romper código anterior. En la implementación de API
  // ya no lee almacenamiento local: solicita el QR temporal al backend.
  Future<String> getQrToken();

  Future<String> redeemReward(String rewardId);
}

// Contrato adicional para repositorios que soportan el nuevo QR temporal.
// Está separado para no romper repositorios mock antiguos.
abstract interface class TemporaryQrRepository {
  Future<TemporaryQr> getCurrentQr();

  Future<TemporaryQr> renewQr();
}
