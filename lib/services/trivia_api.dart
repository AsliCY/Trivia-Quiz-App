import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

class TriviaAPI {
  final String baseUrl = 'https://opentdb.com/api.php';

  Future<List<dynamic>?> fetchQuestions({int amount = 10}) async {
    final url = Uri.parse('$baseUrl?amount=$amount');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['response_code'] == 0) {
        final questions = data['results'];
        for (var question in questions) {
          question['question'] = parse(question['question']).body!.text;
          question['correct_answer'] =
              parse(question['correct_answer']).body!.text;
          question['incorrect_answers'] =
              (question['incorrect_answers'] as List)
                  .map((answer) => parse(answer).body!.text)
                  .toList();
        }
        return questions;
      }
    }
    return null;
  }
}
