import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdProvider with ChangeNotifier {
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  RewardedAd? get rewardedAd => _rewardedAd;

  void loadRewardedAd() {
    if (_isAdLoading) return;
    _isAdLoading = true;
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isAdLoading = false;
          notifyListeners();
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('RewardedAd failed to load: $error');
          _rewardedAd = null;
          _isAdLoading = false;
          notifyListeners();
        },
      ),
    );
  }

  Future<void> showRewardedAd(Function onRewarded) async {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          loadRewardedAd();
        },
      );
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        onRewarded();
      });
      _rewardedAd = null;
    } else {
      print("Ad is not loaded yet");
      // Jika iklan belum tersedia, tetap panggil callback
      onRewarded();
    }
  }
}
