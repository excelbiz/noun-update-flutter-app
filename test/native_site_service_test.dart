import 'package:flutter_test/flutter_test.dart';
import 'package:noun_update_student_app/screens/native_site_service.dart';

void main(){
  test('relative NOUN Update paths resolve safely',(){
    expect(safeNounUpdateDestination('/mock')?.toString(),'https://nounupdate.com/mock');
    expect(safeNounUpdateDestination('result')?.toString(),'https://nounupdate.com/result');
  });

  test('absolute NOUN Update and subdomain URLs are allowed',(){
    expect(safeNounUpdateDestination('https://nounupdate.com/marketplace')?.host,'nounupdate.com');
    expect(safeNounUpdateDestination('https://app.nounupdate.com/tool')?.host,'app.nounupdate.com');
  });

  test('unsafe or lookalike destinations are rejected',(){
    expect(safeNounUpdateDestination('http://nounupdate.com/result'),isNull);
    expect(safeNounUpdateDestination('https://nounupdate.com.attacker.test/result'),isNull);
    expect(safeNounUpdateDestination('javascript:alert(1)'),isNull);
    expect(safeNounUpdateDestination(''),isNull);
  });
}
