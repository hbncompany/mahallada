// lib/screens/about_app_screen.dart
import 'package:flutter/material.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

// Function to launch URL in the browser
_launchURLBrowser() async {
  var _url = Uri.parse("https://hbncompany.pythonanywhere.com/");
  if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $_url');
  }
}

// Function to launch URL in the app
_launchURLApp() async {
  var _url = Uri.parse("https://hbncompany.pythonanywhere.com/");
  if (!await launchUrl(_url, mode: LaunchMode.inAppWebView)) {
    throw Exception('Could not launch $_url');
  }
}

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('aboutApp')), // "Ilova haqida"
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                'assets/app_logo.png', // Ilova logosi (agar mavjud bo'lsa)
                height: 120,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                localizations.translate('appName'),
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                localizations.translate('appVersion') +
                    ': 1.0.0', // "Ilova versiyasi"
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              localizations
                  .translate('aboutAppDescriptionTitle'), // "Ilova haqida"
              textDirection: TextDirection.ltr,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              localizations.translate('aboutAppDescription'), // Ilova tavsifi
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            Text(
              localizations.translate('contactUs'), // "Biz bilan bog'lanish"
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.email, color: Theme.of(context).primaryColor),
              title: Text('hbncompanyofficials@gmail.uz',
                  style: Theme.of(context).textTheme.bodyLarge),
              onTap: () {
                // Elektron pochta orqali bog'lanish
              },
            ),
            ListTile(
              leading: Icon(Icons.web, color: Theme.of(context).primaryColor),
              title: Text('www.hbncompany.pythonanywhere.com',
                  style: Theme.of(context).textTheme.bodyLarge),
              onTap: () {
                _launchURLBrowser();
                // Veb-saytga o'tish
              },
            ),
            const SizedBox(height: 30),
            Center(
              child: Text(
                localizations.translate('copyright'), // "Mualliflik huquqi"
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
