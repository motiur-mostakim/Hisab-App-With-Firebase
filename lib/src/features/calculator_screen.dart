import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'dart:math' as math;

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String equation = "0";
  String result = "0";
  bool isScientific = false;

  void onPressed(String text) {
    setState(() {
      if (text == "C") {
        equation = "0";
        result = "0";
      } else if (text == "⌫") {
        if (equation != "0") {
          equation = equation.substring(0, equation.length - 1);
          if (equation.isEmpty) equation = "0";
        }
      } else if (text == "=") {
        evaluate(finalEval: true);
      } else {
        if (equation == "0") {
          if (_isOperator(text) && text != "-") {
            return; // Can't start with most operators
          }
          if (_isFunction(text)) {
            equation = "$text(";
          } else {
            equation = text;
          }
        } else {
          // Handle operator replacement
          if (_isOperator(text) && _isOperator(equation.substring(equation.length - 1))) {
            equation = equation.substring(0, equation.length - 1) + text;
          } else if (text == ".") {
            // Prevent multiple dots in one number
            String lastPart = equation.split(RegExp(r'[+\-×÷%^()]')).last;
            if (lastPart.contains(".")) return;
            equation += text;
          } else if (_isFunction(text)) {
            equation += "$text(";
          } else {
            equation += text;
          }
        }
        // Auto-evaluate as we type for a better experience
        evaluate(finalEval: false);
      }
    });
  }

  bool _isOperator(String text) {
    return ["+", "-", "×", "÷", "%", "^"].contains(text);
  }

  bool _isFunction(String text) {
    return ["sin", "cos", "tan", "log", "ln", "sqrt"].contains(text);
  }

  void evaluate({required bool finalEval}) {
    try {
      String exp = equation;
      exp = exp.replaceAll("×", "*");
      exp = exp.replaceAll("÷", "/");
      exp = exp.replaceAll("π", math.pi.toString());
      exp = exp.replaceAll("e", math.e.toString());
      exp = exp.replaceAll("%", "/100");
      
      // Handle log as base 10: log(x) -> log(10, x)
      exp = exp.replaceAll("log(", "log(10,");

      // Auto-close parentheses
      int openParen = "(".allMatches(exp).length;
      int closeParen = ")".allMatches(exp).length;
      while (openParen > closeParen) {
        exp += ")";
        closeParen++;
      }

      // Factorial handling (basic)
      RegExp factorialRegex = RegExp(r"(\d+)\!");
      exp = exp.replaceAllMapped(factorialRegex, (Match m) {
        int n = int.parse(m.group(1)!);
        return _calculateFactorial(n).toString();
      });

      Parser p = Parser();
      Expression expression = p.parse(exp);
      ContextModel cm = ContextModel();
      double eval = expression.evaluate(EvaluationType.REAL, cm);

      String res = eval.toString();
      if (res.endsWith(".0")) {
        res = res.substring(0, res.length - 2);
      }
      
      // Format long numbers
      if (res.length > 15) {
        res = eval.toStringAsExponential(4);
      }

      if (finalEval) {
        equation = res;
        result = "0";
      } else {
        result = res;
      }
    } catch (e) {
      if (finalEval) {
        result = "Error";
      }
      // If not final, we don't show error yet as equation might be incomplete
    }
  }

  double _calculateFactorial(int n) {
    if (n < 0) return 0;
    if (n == 0 || n == 1) return 1;
    double res = 1;
    for (int i = 2; i <= n; i++) {
      res *= i;
    }
    return res;
  }

  Widget buildButton(
    String text, {
    Color? bgColor,
    Color? textColor,
    int flex = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => onPressed(text),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: bgColor ?? (isDark ? Colors.grey[850] : Colors.grey[200]),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor ?? (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRow(List<Widget> children) {
    return Expanded(child: Row(children: children));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0C1F) : Colors.white,
      appBar: AppBar(
        title: const Text("ক্যালকুলেটর", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isScientific ? Icons.grid_view_rounded : Icons.science_rounded,
                color: const Color(0xFF60DCB2)),
            onPressed: () {
              setState(() {
                isScientific = !isScientific;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          /// DISPLAY
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      equation,
                      style: TextStyle(
                        fontSize: 28,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    child: Text(
                      result == "0" ? "" : result,
                      style: TextStyle(
                        fontSize: 48,
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, indent: 20, endIndent: 20),

          /// BUTTON GRID
          Expanded(
            flex: 8,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  if (isScientific) ...[
                    buildRow([
                      buildButton("sin", textColor: Colors.blue),
                      buildButton("cos", textColor: Colors.blue),
                      buildButton("tan", textColor: Colors.blue),
                      buildButton("sqrt", textColor: Colors.blue),
                    ]),
                    buildRow([
                      buildButton("log", textColor: Colors.blue),
                      buildButton("ln", textColor: Colors.blue),
                      buildButton("(", textColor: Colors.blue),
                      buildButton(")", textColor: Colors.blue),
                    ]),
                    buildRow([
                      buildButton("^", textColor: Colors.blue),
                      buildButton("π", textColor: Colors.blue),
                      buildButton("e", textColor: Colors.blue),
                      buildButton("!", textColor: Colors.blue),
                    ]),
                  ],

                  buildRow([
                    buildButton(
                      "C",
                      bgColor: Colors.redAccent.withOpacity(0.1),
                      textColor: Colors.redAccent,
                    ),
                    buildButton(
                      "⌫",
                      bgColor: Colors.orange.withOpacity(0.1),
                      textColor: Colors.orange,
                    ),
                    buildButton("%", textColor: const Color(0xFF60DCB2)),
                    buildButton(
                      "÷",
                      bgColor: const Color(0xFF60DCB2).withOpacity(0.1),
                      textColor: const Color(0xFF60DCB2),
                    ),
                  ]),
                  buildRow([
                    buildButton("7"),
                    buildButton("8"),
                    buildButton("9"),
                    buildButton(
                      "×",
                      bgColor: const Color(0xFF60DCB2).withOpacity(0.1),
                      textColor: const Color(0xFF60DCB2),
                    ),
                  ]),
                  buildRow([
                    buildButton("4"),
                    buildButton("5"),
                    buildButton("6"),
                    buildButton(
                      "-",
                      bgColor: const Color(0xFF60DCB2).withOpacity(0.1),
                      textColor: const Color(0xFF60DCB2),
                    ),
                  ]),
                  buildRow([
                    buildButton("1"),
                    buildButton("2"),
                    buildButton("3"),
                    buildButton(
                      "+",
                      bgColor: const Color(0xFF60DCB2).withOpacity(0.1),
                      textColor: const Color(0xFF60DCB2),
                    ),
                  ]),
                  buildRow([
                    buildButton("0"),
                    buildButton("."),
                    buildButton(
                      "=",
                      bgColor: const Color(0xFF60DCB2),
                      textColor: Colors.white,
                      flex: 2,
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
