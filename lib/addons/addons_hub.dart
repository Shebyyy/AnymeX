import 'package:anymex/addons/clip/clip_addon.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:get/get.dart';

/// The one place that makes sure [AddonManager] exists and that the add-ons
/// owned by this app are registered in it. Safe to call many times, in any
/// order relative to other code that creates the manager.
class AddonsHub {
  AddonsHub._();

  static AddonManager manager() {
    final m = Get.isRegistered<AddonManager>()
        ? Get.find<AddonManager>()
        : Get.put(AddonManager());
    _register(m, ClipAddon());
    return m;
  }

  static ClipAddon get clip => manager().byId('clip') as ClipAddon;

  static void _register(AddonManager m, Addon addon) {
    if (m.byId(addon.id) != null) return;
    m.addons.add(addon);
    // AddonManager only checks `isInstalled` for add-ons present at onInit.
    addon.isInstalled().then((v) => addon.installed.value = v).catchError((_) {
      addon.installed.value = false;
    });
  }
}
