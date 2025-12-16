import 'package:auto_channel_market_publish/manager/config_manager.dart';
import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';

class EditProjectConfigScreen extends StatefulWidget {
  const EditProjectConfigScreen({super.key, this.projectConfig});
  final ProjectConfig? projectConfig;

  @override
  State<EditProjectConfigScreen> createState() => _EditProjectConfigScreenState();
}

class _EditProjectConfigScreenState extends State<EditProjectConfigScreen> {
  late ProjectConfig tempProjectConfig;
  TextEditingController appNameController = TextEditingController();
  TextEditingController packageNameController = TextEditingController();
  TextEditingController apkDirController = TextEditingController();
  TextEditingController apkNameContainsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tempProjectConfig = widget.projectConfig ?? ProjectConfig.defaultProjectConfig();
    appNameController.text = tempProjectConfig.appName;
    packageNameController.text = tempProjectConfig.packageName;
    apkDirController.text = tempProjectConfig.apkDir;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tempProjectConfig.id == 0 ? "新增项目配置" : "编辑项目配置")),
      body: Container(
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("id:${tempProjectConfig.id}"),
            Container(
              width: 250,
              child: _buildInput(
                labelText: "app名称",
                hintText: "将作为唯一标识",
                errorText: "",
                controller: appNameController,
                onChanged: (value) {
                  tempProjectConfig.appName = value;
                  setState(() {});
                },
              ),
            ),
            Container(
              width: 250,
              child: _buildInput(
                labelText: "app包名",
                hintText: "请输入app包名",
                errorText: "",
                controller: packageNameController,
                onChanged: (value) {
                  tempProjectConfig.packageName = value;
                  setState(() {});
                },
              ),
            ),
            Container(
              width: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text("apk目录", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      Text("* ", style: TextStyle(color: Colors.red)),
                      TextButton(
                        onPressed: () {
                          FilePicker.platform.pickFileAndDirectoryPaths().then((value) {
                            if (value != null) {
                              tempProjectConfig.apkDir = value.first;
                              setState(() {});
                            }
                          });
                        },
                        child: Text("选择"),
                      ),
                    ],
                  ),
                  Text(
                    tempProjectConfig.apkDir.isEmpty ? "未选择" : tempProjectConfig.apkDir,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: tempProjectConfig.apkDir.isEmpty ? Colors.grey.shade400 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Container(
              width: 250,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (tempProjectConfig.id > 0)
                    GestureDetector(
                      onTap: () {
                        //确认弹窗
                        SmartDialog.show(
                          builder: (bcontext) {
                            return AlertDialog(
                              title: Text("确认删除"),
                              content: Text("确认删除此项目配置吗？"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    SmartDialog.dismiss();
                                  },
                                  child: Text("取消"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ConfigManager().deleteLocalConfig(tempProjectConfig);
                                    SmartDialog.dismiss();
                                    GoRouter.of(context).pop();
                                  },
                                  child: Text("确认"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Center(
                          child: Text("删除", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () {
                      if (tempProjectConfig.isComplete()) {
                        ConfigManager().saveLocalConfig(tempProjectConfig);
                        GoRouter.of(context).pop();
                      }
                    },
                    child: Container(
                      width: 180,
                      height: 40,
                      decoration: BoxDecoration(
                        color: tempProjectConfig.isComplete() ? Colors.blue : Colors.grey,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Text("更新", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required String labelText,
    String hintText = "",
    String errorText = "",
    TextEditingController? controller,
    required Function(String) onChanged,
    bool isMust = true,
  }) {
    return TextField(
      controller: controller,
      onChanged: (value) {
        onChanged(value);
      },
      style: TextStyle(fontSize: 13),
      decoration: InputDecoration(
        label: Row(
          children: [
            Text(labelText),
            if (isMust) Text("*", style: TextStyle(color: Colors.red)),
          ],
        ),
        hintText: hintText,
        errorText: errorText,
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        errorStyle: TextStyle(fontSize: 10, color: Colors.red),
      ),
    );
  }
}
