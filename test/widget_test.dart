import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eps_topik_app/main.dart';
import 'package:eps_topik_app/core/services/language_service.dart';
import 'package:eps_topik_app/core/services/auth_service.dart';

void main() {
  setUp(() {
    LanguageService.instance.setLanguage(AppLanguage.nepali);
  });

  testWidgets('EpsTopikApp smoke test and launch', (WidgetTester tester) async {
    await tester.pumpWidget(const EpsTopikApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  test('LanguageService translations and switching test', () {
    final lang = LanguageService.instance;

    // Test Nepali
    lang.setLanguage(AppLanguage.nepali);
    expect(lang.isNepali, true);
    expect(lang.isEnglish, false);
    expect(lang.isKorean, false);
    expect(lang.readingSectionText(), 'रिडिङ (१-२०)');
    expect(lang.listeningSectionText(), 'लिसनिङ (२१-४०)');
    expect(lang.trDifficulty('intermediate'), 'मध्यम');
    expect(lang.statusText('सक्रिय'), 'सक्रिय');

    // Test English
    lang.setLanguage(AppLanguage.english);
    expect(lang.isNepali, false);
    expect(lang.isEnglish, true);
    expect(lang.isKorean, false);
    expect(lang.readingSectionText(), 'Reading (1-20)');
    expect(lang.listeningSectionText(), 'Listening (21-40)');
    expect(lang.trDifficulty('intermediate'), 'Medium');
    expect(lang.statusText('सक्रिय'), 'Active');
    expect(lang.roleText(UserRole.student), 'Student / Candidate');

    // Test Korean
    lang.setLanguage(AppLanguage.korean);
    expect(lang.isNepali, false);
    expect(lang.isEnglish, false);
    expect(lang.isKorean, true);
    expect(lang.readingSectionText(), '읽기 (1-20)');
    expect(lang.listeningSectionText(), '듣기 (21-40)');
    expect(lang.trDifficulty('intermediate'), '중급');
    expect(lang.statusText('सक्रिय'), '활성');
    expect(lang.roleText(UserRole.student), '수험생 / 학생');
  });

  testWidgets('LanguageSwitcherWidget changes language and notifies listeners', (WidgetTester tester) async {
    final lang = LanguageService.instance;
    lang.setLanguage(AppLanguage.nepali);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: lang,
            builder: (context, _) => Column(
              children: [
                lang.buildLanguageSwitcherWidget(),
                Text(lang.trText(ne: 'गृहपृष्ठ', en: 'Home', ko: '홈')),
              ],
            ),
          ),
        ),
      ),
    );

    // Initial check (Nepali)
    expect(find.text('गृहपृष्ठ'), findsOneWidget);

    // Tap English button
    await tester.tap(find.text('🇬🇧 EN'));
    await tester.pumpAndSettle();
    expect(lang.isEnglish, true);
    expect(find.text('Home'), findsOneWidget);

    // Tap Korean button
    await tester.tap(find.text('🇰🇷 KO'));
    await tester.pumpAndSettle();
    expect(lang.isKorean, true);
    expect(find.text('홈'), findsOneWidget);

    // Tap Nepali button
    await tester.tap(find.text('🇳🇵 NE'));
    await tester.pumpAndSettle();
    expect(lang.isNepali, true);
    expect(find.text('गृहपृष्ठ'), findsOneWidget);
  });
}
