import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock/wakelock.dart';
import 'home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 设置应用为横屏模式
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // 保持屏幕常亮
  Wakelock.enable();
  
  // 设置为全屏
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '机械狗控制器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF151515),
        textTheme: const TextTheme(
          bodyText1: TextStyle(color: Color(0xFFEFEFEF)),
          bodyText2: TextStyle(color: Color(0xFFEFEFEF)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
} 