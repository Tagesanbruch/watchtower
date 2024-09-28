import 'package:flutter/material.dart';
import 'package:get/get.dart';


import 'bluetooth_page/bluetooth_page.dart';
import 'user_page/user_page.dart';
import 'user_page/register_page.dart';
import 'user_page/login_page.dart';
import 'mock_page/mock_page.dart';
import 'record_page/record_page.dart';
import 'signal_page/signal_page.dart';
import 'view_record_page/view_record_page.dart';
import 'settings_page/settings_page.dart';
import 'mock_page/resp_page.dart';

/// start with bluetooth view
const entryURL = "/bluetooth";

/// all pages should be provided
final List<AppPage> navigationList = [
  AppPage("bluetooth", "setupBLEDevice", () => BluetoothPage(),
      Icons.devices_other, Icons.devices_other_outlined),
  AppPage("mock", "setupMockDevice", () => MockPage(), Icons.file_open,
      Icons.file_open_outlined),
  AppPage("signal", "viewSignal", () => SignalPage(), Icons.timeline,
      Icons.timeline_outlined,
      hidden: true),
  AppPage("record", "recordManagement", () => RecordPage(), Icons.save,
      Icons.save_rounded),
  AppPage("viewRecord", "viewSignalRecord", () => ViewRecordPage(),
      Icons.troubleshoot, Icons.troubleshoot_outlined,
      hidden: true),
  AppPage("user", "userPage", () => UserPage(), Icons.card_membership,
      Icons.card_membership_outlined),
  AppPage("login", "login", () => LoginPage(), Icons.local_activity,
      Icons.local_activity_outlined,
      hidden: true), //TODO: change Icon
  AppPage("register", "register", () => RegisterPage(), Icons.local_activity,
      Icons.local_activity_outlined,
      hidden: true), //TODO: change Icon
  AppPage("settings", "settings", () => SettingsPage(), Icons.settings,
      Icons.settings,
      hidden: true),
  AppPage("respiratory", "respiratory", () => RespPage(), Icons.settings,
      Icons.health_and_safety,
      hidden: true),
];

/// hide pages marked with "hidden: true"
final List<AppPage> shownNavigationList =
    navigationList.where((item) => !item.hidden).toList();

class AppPage {
  /// internal name for navigation
  final String name;

  /// appbar title
  final String title;

  /// page content (created with makePage function)
  final Widget Function() page;

  /// icon for navigation drawer
  final IconData icon;

  /// icon when selected
  final IconData selectedIcon;

  /// should this page be hidden in navigationDrawer
  final bool hidden;

  AppPage(this.name, this.title, this.page, this.icon, this.selectedIcon,
      {this.hidden = false});
}

/// appbar implementation
class DefaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showDrawerButton;
  final List<Widget> actions;
  const DefaultAppBar(this.title,
      {this.showDrawerButton = true, this.actions = const [], super.key});

  @override
  Widget build(BuildContext context) {
    final ScaffoldState? scaffoldState =
        context.findRootAncestorStateOfType<ScaffoldState>();
    return AppBar(
      leading: showDrawerButton
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: scaffoldState?.openDrawer,
            )
          : null,
      title: Text(title.tr),
      actions: actions,
    );
  }

  @override
  final Size preferredSize = const Size.fromHeight(kToolbarHeight);
}

/// function for making a page
/// injects appbar and routing information
Widget makePage(String title, Widget body,
    {bool showDrawerButton = true,
    List<Widget> actions = const [],
    Widget? floatingActionButton}) {
//   EasyLoading.init(); //TODO: fix the EasyLoading Initial
  return Scaffold(
    appBar: DefaultAppBar(title,
        showDrawerButton: showDrawerButton, actions: actions),
    body: SafeArea(child: body),
    floatingActionButton: floatingActionButton,
  );
}
