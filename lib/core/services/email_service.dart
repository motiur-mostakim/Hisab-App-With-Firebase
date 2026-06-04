import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static const String _smtpServer = 'smtp.gmail.com';
  static const int _smtpPort = 587;

  /// Gmail এর জন্য আপনার app-specific password প্রয়োজন
  /// https://myaccount.google.com/apppasswords এ যান এবং 16 digit password তৈরি করুন
  
  Future<bool> sendReportEmail({
    required String recipientEmail,
    required String userName,
    required File pdfFile,
    String? customMessage,
  }) async {
    try {
      // Gmail SMTP configuration
      // Note: আপনাকে environment variable বা secure storage ব্যবহার করতে হবে credentials এর জন্য
      // এটি শুধুমাত্র example - production এ secure করুন
      
      final smtpServer = gmail(
        'your-email@gmail.com', // আপনার Gmail address
        'your-app-password',     // App-specific password (16 digit)
      );

      final message = Message()
        ..from = const Address('your-email@gmail.com', 'Hisab App')
        ..recipients.add(recipientEmail)
        ..subject = 'আপনার আর্থিক রিপোর্ট - Hisab App'
        ..text = customMessage ??
            '''
নমস্কার $userName,

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

/// সহজ সমাধান - Flutter এর built-in email composer ব্যবহার করুন
/// এর জন্য 'url_launcher' প্যাকেজ ব্যবহার করুন
class EmailLauncherService {
  static Future<void> openEmailComposer({
    required String recipientEmail,
    required String subject,
    required String body,
  }) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: recipientEmail,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      // ignore: deprecated_member_use
      // await launchUrl(emailLaunchUri);
    } catch (e) {
      print('Email খোলার সময় error: $e');
    }
  }
}

