import 'dart:async';

import 'package:YouOweMe/resources/notifiers/meNotifier.dart';
import 'package:YouOweMe/ui/Abstractions/yomAvatar.dart';
import 'package:YouOweMe/ui/NewOwe/contactSelector.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'package:YouOweMe/ui/NewOwe/peopleList.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class NewOwe extends StatefulWidget {
  @override
  _NewOweState createState() => _NewOweState();
}

class _NewOweState extends State<NewOwe> {
  final TextEditingController titleController = TextEditingController();

  final TextEditingController amountController = TextEditingController();

  final PanelController panelController = PanelController();

  final BehaviorSubject<Contact> selectedContactController = BehaviorSubject();

  final _formKey = GlobalKey<FormState>();

  String titleValidator(String text) {
    if (text.length == 0) {
      return "Enter a valid text";
    }
    return null;
  }

  String amountValidator(String text) {
    if (text.length == 0) {
      return "Enter a valid number";
    }
  }

  void clearSelectedContact() {
    selectedContactController.add(null);
  }

  @override
  Widget build(BuildContext context) {
    TargetPlatform platform = Theme.of(context).platform;
    void addNewOwe() {
      try {
        bool isValidated = _formKey.currentState.validate();
        if (!isValidated) {
          throw ("Not Validatd");
        }
        final newOweMutation = '''
        mutation (\$input :  NewOweInputType!) {
          newOwe(data: \$input) {
            id
            title
          }
        }
      ''';
        String mobileNo = selectedContactController.value.phones.first.value
            .replaceAll(' ', '');
        if (!mobileNo.startsWith('+91')) {
          mobileNo = '+91' + mobileNo;
        }
        print(mobileNo);
        Provider.of<MeNotifier>(context, listen: false)
            .graphQLClient
            .mutate(MutationOptions(
                documentNode: gql(newOweMutation),
                variables: {
                  "input": {
                    "title": titleController.text,
                    "amount": int.parse(amountController.text),
                    "mobileNo": mobileNo,
                    "displayName": selectedContactController.value.displayName
                  }
                },
                onError: (e) {
                  print(e);
                },
                onCompleted: (a) {
                  Provider.of<MeNotifier>(context, listen: false).refresh();
                  Navigator.pop(context);
                }));
      } catch (e) {}
    }

    Future<bool> onWilPopScope() async {
      if (panelController.isAttached && panelController.isPanelOpen) {
        await panelController.close();
        return false;
      }
      return true;
    }

    // void clearHiveBox() {
    //   Box<Owe> oweBox = Hive.box('oweBox');
    //   oweBox.clear();
    // }
    return MultiProvider(
      providers: [
        Provider<BehaviorSubject<Contact>>.value(
          value: selectedContactController,
        ),
        Provider.value(value: panelController)
      ],
      child: Provider.value(
        value: panelController,
        child: WillPopScope(
          onWillPop: onWilPopScope,
          child: Scaffold(
            floatingActionButton: platform == TargetPlatform.android
                ? FloatingActionButton(
                    child: Icon(Icons.check),
                    onPressed: addNewOwe,
                  )
                : null,
            body: SafeArea(
              child: SlidingUpPanel(
                minHeight: 0,
                // maxHeight: MediaQuery.of(context).size.height * 0.5,
                parallaxEnabled: true,
                panelSnapping: false,
                padding: EdgeInsets.all(15),
                controller: panelController,
                backdropTapClosesPanel: true,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  topRight: Radius.circular(15.0),
                ),
                panelBuilder: (ScrollController sc) => ContactSelector(
                  scrollController: sc,
                ),
                body: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.all(15),
                    children: <Widget>[
                      Container(),
                      Text("Title",
                          style: Theme.of(context).textTheme.headline3),
                      TextFormField(
                        controller: titleController,
                        validator: titleValidator,
                        cursorColor: Theme.of(context).accentColor,
                        decoration: InputDecoration.collapsed(
                          hintText:
                              "Enter the reasoning behind this transaction",
                        ),
                        maxLines: 2,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text("Select Person",
                          style: Theme.of(context).textTheme.headline3),
                      PeopleList(),
                      SizedBox(
                        height: 10,
                      ),
                      StreamBuilder(
                        stream: selectedContactController.stream,
                        builder: (BuildContext context, snapshot) {
                          if (!snapshot.hasData) return Container();
                          return Text(
                            "Selected Person",
                            style: Theme.of(context).textTheme.headline3,
                          );
                        },
                      ),
                      StreamBuilder(
                        stream: selectedContactController.stream,
                        builder: (BuildContext context,
                            AsyncSnapshot<Contact> snapshot) {
                          if (!snapshot.hasData) return Container();
                          return Container(
                            height: 50,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                YomAvatar(
                                  text: snapshot.data.displayName != null
                                      ? snapshot.data.displayName
                                          .split(" ")
                                          .map((e) => e[0])
                                          .take(2)
                                          .join()
                                      : "+91",
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                Text(
                                  snapshot.data.displayName ??
                                      snapshot.data.phones.first.value,
                                  style: Theme.of(context).textTheme.headline3,
                                ),
                                Expanded(child: Container()),
                                CupertinoButton(
                                  minSize: 20,
                                  padding: EdgeInsets.all(5),
                                  onPressed: clearSelectedContact,
                                  child: Icon(
                                    CupertinoIcons.clear_thick_circled,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Text(
                        "How much money did you lend?",
                        style: Theme.of(context).textTheme.headline3,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "₹",
                            style: TextStyle(
                                fontSize: 100,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).accentColor),
                          ),
                          Expanded(
                            child: TextFormField(
                                controller: amountController,
                                validator: amountValidator,
                                cursorColor: Theme.of(context).accentColor,
                                decoration: InputDecoration(
                                  hintText: "00",
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(0),
                                ),
                                style: TextStyle(
                                    fontSize: 100,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).accentColor),
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: false, signed: false)),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      if (platform == TargetPlatform.iOS)
                        Container(
                          height: 60,
                          width: 400,
                          child: CupertinoButton.filled(
                              disabledColor: Theme.of(context).accentColor,
                              child: Text('Done'),
                              onPressed: addNewOwe),
                        )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
