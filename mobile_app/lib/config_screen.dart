import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({Key? key}) : super(key: key);

  @override
  _ConfigScreenState createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _espIpController = TextEditingController();
  final TextEditingController _piIpController = TextEditingController();
  final TextEditingController _piPortController = TextEditingController();
  
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  @override
  void dispose() {
    _espIpController.dispose();
    _piIpController.dispose();
    _piPortController.dispose();
    super.dispose();
  }
  
  // 加载保存的设置
  Future<void> _loadSettings() async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _espIpController.text = prefs.getString('esp_ip') ?? '192.168.107.172';
        _piIpController.text = prefs.getString('pi_ip') ?? '192.168.107.172';
        _piPortController.text = prefs.getInt('pi_port')?.toString() ?? '8000';
      });
    } catch (e) {
      // 错误处理
      print('加载设置错误: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  // 保存设置
  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });
      
      try {
        final prefs = await SharedPreferences.getInstance();
        
        await prefs.setString('esp_ip', _espIpController.text);
        await prefs.setString('pi_ip', _piIpController.text);
        await prefs.setInt('pi_port', int.parse(_piPortController.text));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设置已保存')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存设置失败: $e')),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: const Color(0xFF151515),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '连接设置',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _espIpController,
                      decoration: const InputDecoration(
                        labelText: 'ESP32 IP地址',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFF222222),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入ESP32 IP地址';
                        }
                        // 简单IP地址验证
                        final RegExp ipRegex = RegExp(
                          r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
                        );
                        if (!ipRegex.hasMatch(value)) {
                          return '请输入有效的IP地址';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _piIpController,
                      decoration: const InputDecoration(
                        labelText: '树莓派 IP地址',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFF222222),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入树莓派 IP地址';
                        }
                        final RegExp ipRegex = RegExp(
                          r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
                        );
                        if (!ipRegex.hasMatch(value)) {
                          return '请输入有效的IP地址';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _piPortController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '树莓派摄像头流端口',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFF222222),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入端口号';
                        }
                        final int? port = int.tryParse(value);
                        if (port == null || port <= 0 || port > 65535) {
                          return '请输入有效的端口号(1-65535)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: const Color(0xFF4247b7),
                        ),
                        onPressed: _saveSettings,
                        child: const Text(
                          '保存设置',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF4247b7)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          '返回',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 