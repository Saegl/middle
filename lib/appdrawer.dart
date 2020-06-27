import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';

import 'users.dart';
import 'dialog.dart';
import 'settings.dart';
import 'userdata.dart';
import 'profile.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(0.0),
        children: <Widget>[
          _Header(),
          _ProfileItem(),
          _UsersItem(),
          _DialogsItem(),
          _SettingsItem(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final snap = context.select((UserData u) => u.snapshot);
    return DrawerHeader(
      child: Container(),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(
            snap['photo'],
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final snap = context.select((UserData u) => u.snapshot);
    return ListTile(
      leading: Icon(Icons.account_circle),
      title: Text('profile'.tr()),
      onTap: () async {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Profile(snap),
          ),
        );
      },
    );
  }
}

class _UsersItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO remove userData
    final userData = context.watch<UserData>();
    return ListTile(
      leading: Icon(Icons.group),
      title: Text('users'.tr()),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FriendList(userData),
          ),
        );
      },
    );
  }
}

class _DialogsItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO remove userData
    final userData = context.watch<UserData>();
    return ListTile(
      leading: Icon(Icons.bubble_chart),
      title: Text('dialogs'.tr()),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DialogList(),
          ),
        );
      },
    );
  }
}

class _SettingsItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.settings),
      title: Text('settings'.tr()),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Settings(),
          ),
        );
      },
    );
  }
}
