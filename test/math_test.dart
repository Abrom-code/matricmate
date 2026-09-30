import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:matricmate/common/widgets/exam/question_content_renderer.dart';

void main() {
  group('LaTeX & Math Rendering Test Matrix', () {
    testWidgets('1. Basic question text', (tester) async {
      const text = 'What is the capital city of Ethiopia?';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.text(text), findsOneWidget);
    });

    testWidgets('2. Inline LaTeX: Solve \\(x+5=10\\)', (tester) async {
      const text = r'Solve \(x+5=10\).';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.byType(Math), findsOneWidget);
      expect(find.textContaining('Solve'), findsOneWidget);
    });

    testWidgets('3. Multiple LaTeX expressions in one string', (tester) async {
      const text = r'If \(x=5\), calculate \(x^2+2x\).';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.byType(Math), findsNWidgets(2));
      expect(find.textContaining('If'), findsOneWidget);
      expect(find.textContaining('calculate'), findsOneWidget);
    });

    testWidgets('4. Fraction: \\(\\frac{3}{4}+\\frac{1}{2}\\)', (tester) async {
      const text = r'Calculate \(\frac{3}{4}+\frac{1}{2}\).';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.byType(Math), findsOneWidget);
      expect(find.textContaining('Calculate'), findsOneWidget);
    });

    testWidgets('5. Square root: \\(\\sqrt{144}\\)', (tester) async {
      const text = r'Find \(\sqrt{144}\).';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.byType(Math), findsOneWidget);
      expect(find.textContaining('Find'), findsOneWidget);
    });

    testWidgets('6. Block equation: quadratic formula', (tester) async {
      const text = '''Use the quadratic formula:

\\[
x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}
\\]''';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.byType(Math), findsOneWidget);
      expect(find.textContaining('Use the quadratic formula:'), findsOneWidget);
    });

    testWidgets('7. Existing formatting + LaTeX: [b]Calculate[/b] \\(x^2+5x+6\\)', (tester) async {
      const text = r'[b]Calculate[/b] \(x^2+5x+6\).';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.byType(Math), findsOneWidget);
      expect(find.textContaining('Calculate'), findsOneWidget);
    });

    testWidgets('8. Subscripts: \\(a_1+a_2+a_3\\)', (tester) async {
      const text = r'Calculate \(a_1+a_2+a_3\).';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.byType(Math), findsOneWidget);
      expect(find.textContaining('Calculate'), findsOneWidget);
    });

    testWidgets('9. Physics: \\(F=ma\\)', (tester) async {
      const text = r'Calculate the force using \(F=ma\).';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.byType(Math), findsOneWidget);
      expect(find.textContaining('Calculate the force using'), findsOneWidget);
    });

    testWidgets('10. Chemistry: \\(2H_2+O_2\\rightarrow2H_2O\\)', (tester) async {
      const text = r'The reaction is \(2H_2+O_2\rightarrow2H_2O\).';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.byType(Math), findsOneWidget);
      expect(find.textContaining('The reaction is'), findsOneWidget);
    });

    testWidgets(r'11. Dollar math: $x = 5$', (tester) async {
      const text = r'Given $x = 5$, find $2x$.';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.byType(Math), findsNWidgets(2));
      expect(find.textContaining('Given'), findsOneWidget);
    });

    testWidgets('12. Invalid LaTeX (unclosed delimiter) does not crash', (tester) async {
      const text = r'Solve \( \frac{x';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.textContaining(r'Solve \( \frac{x'), findsOneWidget);
    });

    testWidgets('13. Invalid LaTeX inside closed delimiter falls back to raw text', (tester) async {
      const text = r'Solve \( \frac{x \)';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.textContaining(r'Solve'), findsOneWidget);
    });

    testWidgets('14. Question order number prepending', (tester) async {
      const text = r'Solve \(x+2=4\).';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(
              qnNumber: 7,
              text: text,
            ),
          ),
        ),
      );
      expect(find.textContaining('7. '), findsOneWidget);
      expect(find.byType(Math), findsOneWidget);
    });

    testWidgets('15. Tables with LaTeX inside cells', (tester) async {
      const text = '''[table]
[row]
[cell]Formula[/cell]
[cell]\\(F=ma\\)[/cell]
[/row]
[/table]''';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.textContaining('Formula'), findsOneWidget);
      expect(find.byType(Math), findsOneWidget);
    });

    testWidgets('16. Dark mode adapts color correctly', (tester) async {
      const text = r'Solve \(x^2=9\).';
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.byType(Math), findsOneWidget);
    });

    testWidgets('17. Existing custom tags ([b], [i], [u], [s], [c=...]) preserved', (tester) async {
      const text = '[b]Bold[/b] [i]Italic[/i] [u]Underline[/u] [s]Strike[/s] [c=#00897B]Teal[/c]';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.textContaining('Bold'), findsOneWidget);
      expect(find.textContaining('Italic'), findsOneWidget);
      expect(find.textContaining('Underline'), findsOneWidget);
      expect(find.textContaining('Strike'), findsOneWidget);
      expect(find.textContaining('Teal'), findsOneWidget);
    });

    testWidgets('18. Mixed BBCode and LaTeX tags together', (tester) async {
      const text = r'[b]Solve[/b] [i]the formula[/i] \(E=mc^2\) [u]carefully[/u].';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.byType(Math), findsOneWidget);
      expect(find.textContaining('Solve'), findsOneWidget);
      expect(find.textContaining('carefully'), findsOneWidget);
    });

    testWidgets('19. Truncated preview text with incomplete LaTeX does not crash', (tester) async {
      // Slicing in the middle of \(x^2 + 5x...
      const text = r'Solve the quadratic equation \(x^2 + 5x...';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.textContaining('Solve the quadratic equation'), findsOneWidget);
    });

    testWidgets('20. Advanced math: Calculus sum and integral', (tester) async {
      const text = r'Evaluate \(\sum_{i=1}^{n}i\) and \(\int_0^1x^2dx\).';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestionContentRenderer(text: text),
          ),
        ),
      );
      expect(find.byType(Math), findsNWidgets(2));
      expect(find.textContaining('Evaluate'), findsOneWidget);
    });

    testWidgets('21. Wide inline equation in narrow container renders without overflow', (tester) async {
      const text = r'Given \(a_1 x_1 + a_2 x_2 + a_3 x_3 + a_4 x_4 + a_5 x_5 + a_6 x_6 + a_7 x_7 = 100\), solve for x.';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: QuestionContentRenderer(text: text),
            ),
          ),
        ),
      );
      expect(find.byType(Math), findsOneWidget);
      expect(find.textContaining('solve for x'), findsOneWidget);
    });

    testWidgets('22. Block math with wide formula is horizontally scrollable', (tester) async {
      const text = r'\[ x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a} + \frac{c_1 + c_2 + c_3 + c_4 + c_5}{d_1 + d_2 + d_3} \]';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: QuestionContentRenderer(text: text),
            ),
          ),
        ),
      );
      expect(find.byType(Math), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });
}

