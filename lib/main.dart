import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:tiktok_clone_app/core/constants/app_colors.dart';
import 'package:tiktok_clone_app/router/app_router.dart'; // <-- your router provider
import 'package:tiktok_clone_app/features/video_feed/screens/video_feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: AppColors.accent,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.black,
        ),
      ),
      routerConfig: router,
    );
  }
}

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _index = 0;

  final pages = [
    const VideoFeedScreen(),
    const Center(child: Text("Search", style: TextStyle(color: Colors.white))),
    const Center(child: Text("Upload", style: TextStyle(color: Colors.white))),
    const Center(child: Text("Inbox", style: TextStyle(color: Colors.white))),
    const Center(child: Text("Profile", style: TextStyle(color: Colors.white))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        items: [
          BottomNavigationBarItem(
              icon: Icon(_index == 0 ? Icons.home_filled : Icons.home_outlined),
              label: ""),
          BottomNavigationBarItem(
              icon: Icon(_index == 1 ? Icons.search_rounded : Icons.search),
              label: ""),
          BottomNavigationBarItem(
            icon: Container(
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            label: "",
          ),
          BottomNavigationBarItem(
              icon: Icon(_index == 3 ? Icons.inbox_rounded : Icons.inbox_sharp),
              label: ""),
          BottomNavigationBarItem(
              icon: Icon(_index == 4 ? Icons.person : Icons.person_2_outlined),
              label: ""),
        ],
      ),
    );
  }
}
