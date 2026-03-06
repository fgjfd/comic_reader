import 'package:flutter/material.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/profile_page.dart';

/// 应用程序入口点
void main() {
  runApp(const MyApp());
}

/// 应用程序根组件
class MyApp extends StatelessWidget {
  /// 构造函数
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comic App', // 应用程序标题
      theme: ThemeData(primarySwatch: Colors.blue), // 应用程序主题，使用蓝色作为主色调
      home: const MainScreen(), // 应用程序首页
    );
  }
}

/// 主屏幕组件，包含底部导航栏
class MainScreen extends StatefulWidget {
  /// 构造函数
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

/// 主屏幕状态管理
class _MainScreenState extends State<MainScreen> {
  /// 当前选中的导航项索引
  int _selectedIndex = 0;

  /// 导航项对应的页面列表
  final List<Widget> _pages = [HomePage(), ProfilePage()];

  /// 导航项点击事件处理函数
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // 更新选中的导航项索引
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // 显示当前选中的页面
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'), // 首页导航项
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ), // 我的导航项
        ],
        currentIndex: _selectedIndex, // 当前选中的导航项索引
        selectedItemColor: Colors.blue, // 选中导航项的颜色
        onTap: _onItemTapped, // 导航项点击事件处理函数
      ),
    );
  }
}
