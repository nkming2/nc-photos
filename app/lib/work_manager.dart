import 'package:nc_photos/image_enhancer_task.dart';
import 'package:workmanager/workmanager.dart';

void initWorkManager() {
  Workmanager().initialize(_callbackDispatcher);
}

@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "imageEnhancer":
        await ImageEnhancerTask(inputData!).run();
        break;
    }
    return true;
  });
}
