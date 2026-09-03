import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/local_hack.dart';

final likedTipsProvider = StateNotifierProvider<LikedTipsNotifier, AsyncValue<List<LocalHack>>>((ref) {
  return LikedTipsNotifier();
});

class LikedTipsNotifier extends StateNotifier<AsyncValue<List<LocalHack>>> {
  LikedTipsNotifier() : super(const AsyncValue.data([]));

  void toggleLike(LocalHack tip) {
    state.whenData((currentList) {
      if (currentList.contains(tip)) {
        state = AsyncValue.data(currentList.where((item) => item != tip).toList());
      } else {
        state = AsyncValue.data([...currentList, tip]);
      }
    });
  }
}