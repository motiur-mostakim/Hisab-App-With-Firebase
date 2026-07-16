import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static const String _smtpServer = 'smtp.gmail.com';
  static const int _smtpPort = 587;

  Future<bool> sendReportEmail({
    required String recipientEmail,
    required String userName,
    required File pdfFile,
    String? customMessage,
  }) async {
    try {
      final smtpServer = gmail('your-email@gmail.com', 'your-app-password');

      final message = Message()
        ..from = const Address('your-email@gmail.com', 'Hisab App')
        ..recipients.add(recipientEmail)
        ..subject = 'আপনার আর্থিক রিপোর্ট - Hisab App'
        ..text =
            customMessage ??
            '''
 $userName,

আপনার আর্থিক বিশ্লেষণ রিপোর্ট সংযুক্ত ফাইলে পাবেন।

এই রিপোর্টে আপনার সমস্ত লেনদেনের বিস্তারিত বিশ্লেষণ রয়েছে।

ধন্যবাদ,
Hisab App টিম
            '''
        ..attachments.add(FileAttachment(pdfFile));

      await send(message, smtpServer);
      return true;
    } catch (e) {
      print('Email পাঠানোর সময় error: $e');
      return false;
    }
  }
}

class EmailLauncherService {
  static Future<void> openEmailComposer({
    required String recipientEmail,
    required String subject,
    required String body,
  }) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: recipientEmail,
      queryParameters: {'subject': subject, 'body': body},
    );

    try {
    } catch (e) {
      print('Email খোলার সময় error: $e');
    }
  }
}
