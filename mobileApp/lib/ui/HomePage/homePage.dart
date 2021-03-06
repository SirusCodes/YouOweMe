import 'dart:ui';

import 'package:YouOweMe/resources/notifiers/meNotifier.dart';
import 'package:YouOweMe/ui/Abstractions/yomAvatar.dart';
import 'package:YouOweMe/ui/HomePage/iOweSection.dart';
import 'package:YouOweMe/ui/HomePage/oweMeSection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:YouOweMe/ui/NewOwe/newOwe.dart';
import 'package:YouOweMe/ui/HomePage/bottomList.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  void logOutDialog(BuildContext context) async {
    bool result = await showCupertinoModalPopup<bool>(
        context: context,
        builder: (BuildContext context) {
          return CupertinoActionSheet(
            title: Text("Logout"),
            message: Text(
                """This action will log you out of the app. I hope you come back again soon, now so that you're here we'll talk a bit a bit bit by bit through the bitly world which runs bit by bit."""),
            cancelButton: CupertinoActionSheetAction(
              child: Text("Cancel"),
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            actions: <Widget>[
              CupertinoActionSheetAction(
                child: Text(
                  "Log me out already. 😪",
                  style: TextStyle(color: CupertinoColors.activeGreen),
                ),
                isDefaultAction: true,
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
            ],
          );
        });
    if (result) {
      FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TargetPlatform platform = Theme.of(context).platform;

    void goToNewOwe() async {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (BuildContext context) => NewOwe()));
    }

    Future<void> onRefresh() =>
        Provider.of<MeNotifier>(context, listen: false).refresh();

    List<Widget> children = <Widget>[
      SizedBox(
        height: 10,
      ),
      OweMeSection(),
      SizedBox(
        height: 10,
      ),
      IOweSection(),
      BottomList(),
    ];

    final Widget abstractedHomePage = CustomScrollView(
      slivers: <Widget>[
        if (platform == TargetPlatform.iOS) ...[
          CupertinoSliverRefreshControl(
            onRefresh: onRefresh,
          ),
          SliverPadding(
              padding: EdgeInsets.all(15),
              sliver: SliverList(delegate: SliverChildListDelegate(children)))
        ] else if (platform == TargetPlatform.android)
          SliverFillRemaining(
            child: RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  padding: EdgeInsets.all(15),
                  children: children,
                )),
          )
      ],
    );

    final Widget abstractedNewOweButton = platform == TargetPlatform.android
        ? FloatingActionButton.extended(
            label: Text('New'),
            icon: Icon(Icons.add),
            onPressed: goToNewOwe,
          )
        : CupertinoButton(
            color: Theme.of(context).accentColor,
            child: Text('New'),
            onPressed: goToNewOwe);
    // : Container();

    final Widget bottomBar = platform == TargetPlatform.iOS
        ? ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.white.withOpacity(0),
                child: CupertinoButton(
                  onPressed: () {},
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.add_circled),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        "Add New Owe",
                        style: TextStyle(fontSize: 18),
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
        : null;

    return Scaffold(
      floatingActionButton: abstractedNewOweButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Stack(
        children: [
          abstractedHomePage,
          Positioned(
            bottom: 20,
            left: 15,
            child: YomAvatar(
              text: Provider.of<MeNotifier>(context)
                  .me
                  .name
                  .split(" ")
                  .map((e) => e[0])
                  .toList()
                  .join(),
              onPressed: () => logOutDialog(context),
            ),
          )
        ],
      ),
      // bottomNavigationBar: bottomBar
    );
  }
}
