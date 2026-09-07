import 'package:flutter_test/flutter_test.dart';
import 'package:noun_update_student_app/widgets/shared_widgets.dart';

void main() {
  test('formats wallet values as Nigerian naira', () {
    expect(formatNaira(1245000), '₦12,450');
    expect(formatNaira(-50000), '-₦500');
  });
}
