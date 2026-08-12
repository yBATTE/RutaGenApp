import 'models.dart';

abstract interface class RutaGenRepository {
  Future<Customer> getCustomer();

  Future<List<Reward>> getRewards();

  Future<List<Movement>> getMovements({
    int page = 1,
    int limit = 20,
  });

  Future<List<NewsItem>> getNews({
    int page = 1,
    int limit = 10,
  });

  Future<NewsItem> getNewsDetail(String newsId);

  Future<List<Station>> getStations();

  Future<String> getQrToken();

  Future<String> redeemReward(String rewardId);
}

abstract interface class TemporaryQrRepository {
  Future<TemporaryQr> getCurrentQr();

  Future<TemporaryQr> renewQr();
}
