import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'config_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _espIpAddress = "192.168.107.172"; // 默认ESP32 IP地址
  String _piIpAddress = "192.168.107.172"; // 默认树莓派IP地址
  int _piStreamPort = 8000; // 默认视频流端口
  bool _isConnected = false;
  bool _isStreamActive = false;
  
  // 控制变量
  int _moveFB = 0; // 前后移动：1=前进，-1=后退，0=停止
  int _moveLR = 0; // 左右转向：1=右转，-1=左转，0=停止
  
  // 防抖控制
  Timer? _debounceTimer;
  
  // 用于控制WebView刷新
  late WebViewController _webViewController;
  final String _streamUrl = "/video_feed";
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  // 加载保存的设置
  void _loadSettings() async {
    // 这里应该使用SharedPreferences加载保存的设置
    // 暂时使用默认值
  }
  
  // 发送控制命令到ESP32
  Future<void> _sendCommand(String variable, int value) async {
    try {
      final response = await http.get(
        Uri.parse('http://$_espIpAddress/control?var=$variable&val=$value&cmd=0'),
        headers: {'Connection': 'keep-alive'},
      ).timeout(const Duration(seconds: 2));
      
      if (response.statusCode == 200) {
        setState(() {
          _isConnected = true;
        });
      } else {
        setState(() {
          _isConnected = false;
        });
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
      });
      print("发送命令错误: $e");
    }
  }
  
  // 处理摇杆移动
  void _handleJoystickMove(StickDragDetails details) {
    // 获取摇杆位置，范围为-1到1
    double x = details.x;
    double y = -details.y; // 注意y轴要反转，因为向上是正方向
    
    // 确定前后移动
    int newMoveFB = 0;
    if (y > 0.3) {
      newMoveFB = 1; // 前进
    } else if (y < -0.3) {
      newMoveFB = -1; // 后退
    }
    
    // 确定左右转向
    int newMoveLR = 0;
    if (x > 0.3) {
      newMoveLR = 1; // 右转
    } else if (x < -0.3) {
      newMoveLR = -1; // 左转
    }
    
    // 只有在移动状态变化时才发送命令
    if (newMoveFB != _moveFB) {
      _moveFB = newMoveFB;
      if (_moveFB == 1) {
        _sendCommand('move', 1); // 前进
      } else if (_moveFB == -1) {
        _sendCommand('move', 5); // 后退
      } else {
        _sendCommand('move', 3); // 停止前后移动
      }
    }
    
    if (newMoveLR != _moveLR) {
      _moveLR = newMoveLR;
      if (_moveLR == 1) {
        _sendCommand('move', 4); // 右转
      } else if (_moveLR == -1) {
        _sendCommand('move', 2); // 左转
      } else {
        _sendCommand('move', 6); // 停止左右转向
      }
    }
  }
  
  // 处理摇杆释放
  void _handleJoystickRelease() {
    if (_moveFB != 0) {
      _moveFB = 0;
      _sendCommand('move', 3); // 停止前后移动
    }
    
    if (_moveLR != 0) {
      _moveLR = 0;
      _sendCommand('move', 6); // 停止左右转向
    }
  }
  
  // 激活/停止视频流
  void _toggleStream() {
    setState(() {
      _isStreamActive = !_isStreamActive;
    });
    
    if (_isStreamActive) {
      _refreshStream();
    }
  }
  
  // 刷新视频流
  void _refreshStream() {
    final String fullUrl = 'http://$_piIpAddress:$_piStreamPort$_streamUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    _webViewController.loadUrl(fullUrl);
  }
  
  // 执行特殊功能
  void _executeFunction(int functionCode) {
    _sendCommand('funcMode', functionCode);
  }
  
  // 构建功能按钮
  Widget _buildFunctionButton(String label, int functionCode, {Color? color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: color ?? const Color(0xFF4247b7),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () => _executeFunction(functionCode),
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧控制区域（轮盘）
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "移动控制",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(75),
                        ),
                        child: Joystick(
                          period: const Duration(milliseconds: 100),
                          mode: JoystickMode.all,
                          listener: _handleJoystickMove,
                          onStickDragEnd: _handleJoystickRelease,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: const Color(0xFF1cb8bd),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => _executeFunction(1),
                    child: const Text("稳定模式"),
                  ),
                ],
              ),
            ),
          ),
          
          // 中间视频区域
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isConnected ? "已连接" : "未连接",
                          style: TextStyle(
                            color: _isConnected ? Colors.green : Colors.red,
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: _isStreamActive
                                    ? Colors.red
                                    : Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: _toggleStream,
                              child: Text(_isStreamActive ? "停止视频" : "启动视频"),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: Colors.grey,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: _isStreamActive ? _refreshStream : null,
                              child: const Text("刷新视频"),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.settings),
                              onPressed: () {
                                // 打开设置页面
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ConfigScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isStreamActive
                        ? WebView(
                            initialUrl: 'http://$_piIpAddress:$_piStreamPort$_streamUrl',
                            javascriptMode: JavascriptMode.unrestricted,
                            onWebViewCreated: (WebViewController webViewController) {
                              _webViewController = webViewController;
                            },
                          )
                        : const Center(
                            child: Text(
                              "点击"启动视频"按钮查看摄像头画面",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          
          // 右侧功能按钮区域
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "功能控制",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        Row(
                          children: [
                            _buildFunctionButton("低姿态", 2, color: Color(0xFFe7e7e7)),
                            _buildFunctionButton("握手", 3, color: Color(0xFFe7e7e7)),
                          ],
                        ),
                        Row(
                          children: [
                            _buildFunctionButton("跳跃", 4, color: Color(0xFFe7e7e7)),
                            _buildFunctionButton("感谢", 10, color: Color(0xFFe7e7e7)),
                          ],
                        ),
                        Row(
                          children: [
                            _buildFunctionButton("动作B", 6, color: Color(0xFFe7e7e7)),
                            _buildFunctionButton("动作C", 7, color: Color(0xFFe7e7e7)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildFunctionButton("初始位置", 8, color: Color(0xFF1cb8bd)),
                            _buildFunctionButton("中间位置", 9, color: Color(0xFF1cb8bd)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "灯光控制",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _sendCommand('light', 1),
                                child: Container(
                                  height: 40,
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _sendCommand('light', 2),
                                child: Container(
                                  height: 40,
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _sendCommand('light', 3),
                                child: Container(
                                  height: 40,
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _sendCommand('light', 0),
                                child: Container(
                                  height: 40,
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    border: Border.all(color: Colors.white),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text("关灯"),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _sendCommand('buzzer', 1),
                                child: Container(
                                  height: 40,
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "蜂鸣器",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _sendCommand('buzzer', 0),
                                child: Container(
                                  height: 40,
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text("停止"),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 