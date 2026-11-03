import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmaster/services/iap_service.dart';

void main() {
  test('iOS maps to the single Gold Star product', () {
    expect(StoreService.productIdsFor(TargetPlatform.iOS), {'mathmasterstar'});
    expect(StoreService.starId, 'mathmasterstar');
  });
  test('Android maps to coffee + chocolate only', () {
    expect(StoreService.productIdsFor(TargetPlatform.android),
        {'mathmastercoffee', 'mathmasterchocolate'});
    expect(StoreService.productIdsFor(TargetPlatform.android),
        isNot(contains('mathmasterstar')));
  });
}
