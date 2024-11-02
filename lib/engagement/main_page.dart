import 'package:flutter/material.dart';
import 'package:web_scraper/engagement/scrape_config_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web Scraper',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: ScraperConfigPage(),
    );
  }
}
