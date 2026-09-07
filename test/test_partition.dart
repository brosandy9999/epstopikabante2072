import 'package:flutter_test/flutter_test.dart';
import 'package:eps_topik_app/features/question_engine/question_template.dart';
import 'package:eps_topik_app/features/admin/paper_exam_html_builder.dart';

void main() {
  test('partitionAcross7Pages creates balanced continuous 7-page distribution', () {
    final qs = <QuestionTemplate>[];
    // Q1-Q4: picture vocabulary
    for (int i = 1; i <= 4; i++) {
      qs.add(UniversalQuestion(
        questionId: 'q$i',
        questionNumber: i,
        isListening: false,
        questionText: '다음 그림을 보고 맞는 단어나 문장을 고르십시오.',
        questionImageUrl: 'https://example.com/img$i.png',
        textOptions: ['가방', '모자', '안경', '우산'],
      ));
    }
    // Q5-Q8: fill in the blank
    for (int i = 5; i <= 8; i++) {
      qs.add(UniversalQuestion(
        questionId: 'q$i',
        questionNumber: i,
        isListening: false,
        questionText: '다음 빈칸에 들어갈 가장 알맞은 것을 고르십시오.\n가: 오늘 저녁에 시간 있어요?\n나: 미안해요. 선약이 있어요.',
        textOptions: ['있어서', '있는데', '있으면', '있지만'],
      ));
    }
    // Q9-Q12: notice / chart
    for (int i = 9; i <= 12; i++) {
      qs.add(UniversalQuestion(
        questionId: 'q$i',
        questionNumber: i,
        isListening: false,
        questionText: '다음 글을 읽고 내용과 같은 것을 고르십시오.',
        questionImageUrl: 'https://example.com/chart$i.png',
        textOptions: ['1번 내용입니다.', '2번 내용입니다.', '3번 내용입니다.', '4번 내용입니다.'],
      ));
    }
    // Q13-Q20: reading passages
    for (int i = 13; i <= 20; i++) {
      qs.add(UniversalQuestion(
        questionId: 'q$i',
        questionNumber: i,
        isListening: false,
        questionText: '다음 글을 읽고 물음에 답하십시오.\n한국 사람들은 밥과 국, 그리고 여러 가지 반찬을 함께 먹습니다. 숟가락으로 밥과 국을 먹고 젓가락으로 반찬을 먹습니다.',
        textOptions: ['한국의 식사 예절', '한국의 음식 문화', '한국의 요리 방법', '한국의 식당 이용'],
      ));
    }
    // Q21-Q40: listening
    for (int i = 21; i <= 40; i++) {
      qs.add(ListeningAudioQuestion(
        questionId: 'q$i',
        questionText: '들리는 것을 고르십시오.',
        audioAssetPath: 'https://example.com/audio$i.mp3',
        textOptions: ['공장', '회사', '식당', '시장'],
      ));
    }

    final pages = PaperExamHtmlBuilder.partitionAcross7Pages(qs, 20);
    expect(pages.length, equals(7));

    int totalQuestions = 0;
    for (int p = 0; p < pages.length; p++) {
      final list = pages[p];
      totalQuestions += list.length;
      // Every page should have between 4 and 7 questions (no page has only 2-3 or 8+ questions)
      expect(list.length >= 4 && list.length <= 7, isTrue,
          reason: 'Page ${p + 2} has ${list.length} questions, which is out of balanced range');
    }
    expect(totalQuestions, equals(40));
  });
}
