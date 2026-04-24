import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String equation = "0";
  String result = "0";
  String expression = "";

  buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == "C") {
        equation = "0";
        result = "0";
      } else if (buttonText == "⌫") {
        if (equation.isNotEmpty && equation != "0") {
          equation = equation.substring(0, equation.length - 1);
        }
        if (equation == "") {
          equation = "0";
        }
      } else if (buttonText == "=") {
        expression = equation;
        expression = expression.replaceAll('×', '*');
        expression = expression.replaceAll('÷', '/');

        try {
          Parser p = Parser();
          Expression exp = p.parse(expression);

          ContextModel cm = ContextModel();
          result = '${exp.evaluate(EvaluationType.REAL, cm)}';
          if (result.endsWith(".0")) {
            result = result.substring(0, result.length - 2);
          }
        } catch (e) {
          result = "Error";
        }
      } else {
        if (equation == "0") {
          equation = buttonText;
        } else {
          equation = equation + buttonText;
        }
      }
    });
  }

  Widget buildButton(String buttonText, double buttonHeight, Color buttonColor, bool isDark) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.1 * buttonHeight,
      decoration: BoxDecoration(
        color: buttonColor,
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 0.5,
        ),
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0.0),
          ),
          padding: const EdgeInsets.all(16.0),
        ),
        onPressed: () => buttonPressed(buttonText),
        child: Text(
          buttonText,
          style: TextStyle(
            fontSize: 30.0,
            fontWeight: FontWeight.normal,
            color: (buttonColor == Colors.redAccent || buttonColor == Colors.blue) 
                ? Colors.white 
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numberBtnColor = isDark ? Colors.black54 : Colors.grey[200]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ক্যালকুলেটর"),
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: <Widget>[
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
              child: Text(
                equation,
                style: TextStyle(
                  fontSize: 38.0, 
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.fromLTRB(10, 30, 10, 0),
              child: Text(
                result,
                style: TextStyle(
                  fontSize: 48.0, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const Expanded(child: Divider()),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  child: Table(
                    children: [
                      TableRow(children: [
                        buildButton("C", 1, Colors.redAccent, isDark),
                        buildButton("⌫", 1, Colors.blue, isDark),
                        buildButton("÷", 1, Colors.blue, isDark),
                      ]),
                      TableRow(children: [
                        buildButton("7", 1, numberBtnColor, isDark),
                        buildButton("8", 1, numberBtnColor, isDark),
                        buildButton("9", 1, numberBtnColor, isDark),
                      ]),
                      TableRow(children: [
                        buildButton("4", 1, numberBtnColor, isDark),
                        buildButton("5", 1, numberBtnColor, isDark),
                        buildButton("6", 1, numberBtnColor, isDark),
                      ]),
                      TableRow(children: [
                        buildButton("1", 1, numberBtnColor, isDark),
                        buildButton("2", 1, numberBtnColor, isDark),
                        buildButton("3", 1, numberBtnColor, isDark),
                      ]),
                      TableRow(children: [
                        buildButton(".", 1, numberBtnColor, isDark),
                        buildButton("0", 1, numberBtnColor, isDark),
                        buildButton("00", 1, numberBtnColor, isDark),
                      ]),
                    ],
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.25,
                  child: Table(
                    children: [
                      TableRow(children: [
                        buildButton("×", 1, Colors.blue, isDark),
                      ]),
                      TableRow(children: [
                        buildButton("-", 1, Colors.blue, isDark),
                      ]),
                      TableRow(children: [
                        buildButton("+", 1, Colors.blue, isDark),
                      ]),
                      TableRow(children: [
                        buildButton("=", 2, Colors.redAccent, isDark),
                      ]),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
