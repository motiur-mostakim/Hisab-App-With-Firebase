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
        if (equation.length > 1) {
          equation = equation.substring(0, equation.length - 1);
        } else {
          equation = "0";
        }
      } else if (text == "=") {
        try {
          String exp = equation
              .replaceAll("×", "*")
              .replaceAll("÷", "/")
              .replaceAll("ln", "ln") // math_expressions handles ln
              .replaceAll(
                "log",
                "log10",
              ); // adjusting for math_expressions logic if needed

          Parser p = Parser();
          Expression expression = p.parse(exp);
          ContextModel cm = ContextModel();

          // Evaluate the expression
          double eval = expression.evaluate(EvaluationType.REAL, cm);
          result = eval.toString();

          if (result.endsWith(".0")) {
            result = result.substring(0, result.length - 2);
          }
        } catch (e) {
          result = "Error";
        }
      } else {
        // Handle scientific functions automatically adding bracket
        List<String> functions = ["sin", "cos", "tan", "log", "ln", "sqrt"];

        if (equation == "0") {
          if (functions.contains(text)) {
            equation = "$text(";
          } else {
            equation = text;
          }
        } else {
          if (functions.contains(text)) {
            equation += "$text(";
          } else {
            equation += text;
          }
        }
      }
    });
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
            color: bgColor ?? (isDark ? Colors.grey[850] : Colors.grey[300]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
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
        title: const Text("ক্যালকুলেটর"),
        actions: [
          IconButton(
            icon: Icon(isScientific ? Icons.grid_view : Icons.science),
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
            flex: 4,
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
                        fontSize: 32,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    result,
                    style: TextStyle(
                      fontSize: 56,
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          /// BUTTON GRID
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.all(8),
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
                      bgColor: Colors.redAccent,
                      textColor: Colors.white,
                    ),
                    buildButton(
                      "⌫",
                      bgColor: Colors.orange,
                      textColor: Colors.white,
                    ),
                    buildButton("%", textColor: const Color(0xFF60DCB2)),
                    buildButton(
                      "÷",
                      bgColor: const Color(0xFF60DCB2).withOpacity(0.2),
                      textColor: const Color(0xFF60DCB2),
                    ),
                  ]),
                  buildRow([
                    buildButton("7"),
                    buildButton("8"),
                    buildButton("9"),
                    buildButton(
                      "×",
                      bgColor: const Color(0xFF60DCB2).withOpacity(0.2),
                      textColor: const Color(0xFF60DCB2),
                    ),
                  ]),
                  buildRow([
                    buildButton("4"),
                    buildButton("5"),
                    buildButton("6"),
                    buildButton(
                      "-",
                      bgColor: const Color(0xFF60DCB2).withOpacity(0.2),
                      textColor: const Color(0xFF60DCB2),
                    ),
                  ]),
                  buildRow([
                    buildButton("1"),
                    buildButton("2"),
                    buildButton("3"),
                    buildButton(
                      "+",
                      bgColor: const Color(0xFF60DCB2).withOpacity(0.2),
                      textColor: const Color(0xFF60DCB2),
                    ),
                  ]),
                  buildRow([
                    buildButton("0", flex: 1),
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
