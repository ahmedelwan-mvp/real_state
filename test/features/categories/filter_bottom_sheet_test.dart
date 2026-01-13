import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/categories/presentation/widgets/filter_bottom_sheet.dart';
import 'package:real_state/features/models/entities/location_area.dart';

import '../../helpers/pump_test_app.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets(
    'shows validation error when min price > max price and disables Apply',
    (WidgetTester tester) async {
      final filter = PropertyFilter();
      await pumpTestApp(
        tester,
        Scaffold(
          body: FilterBottomSheet(
            onAddLocation: () async {},
            currentFilter: filter,
            locationAreas: [
              LocationArea(
                id: '1',
                nameAr: 'Area 1',
                nameEn: 'Area 1',
                imageUrl: '',
                isActive: true,
                createdAt: DateTime.now(),
              ),
            ],
            onApply: (_) {},
          ),
        ),
      );

      final applyFinder = find.byKey(filterApplyButtonKey);
      await pumpUntilFound(tester, applyFinder);
      final applyButton = tester.widget<PrimaryButton>(applyFinder);
      expect(applyButton.onPressed, isNotNull);

      await tester.enterText(find.byKey(filterMinPriceInputKey), '100');
      await tester.enterText(find.byKey(filterMaxPriceInputKey), '50');
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('price_error_range'.tr()), findsOneWidget);

      final applyButtonAfter = tester.widget<PrimaryButton>(applyFinder);
      expect(applyButtonAfter.onPressed, isNull);
    },
  );
}
