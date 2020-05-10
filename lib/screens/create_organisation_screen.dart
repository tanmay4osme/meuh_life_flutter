import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:meuh_life/models/Organisation.dart';
import 'package:meuh_life/models/Profile.dart';
import 'package:meuh_life/services/DatabaseService.dart';
import 'package:meuh_life/services/SharedPreferencesService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateOrganisationScreen extends StatefulWidget {
  CreateOrganisationScreen(this.userID);

  final String userID;

  @override
  _CreateOrganisationScreenState createState() =>
      _CreateOrganisationScreenState();
}

class _CreateOrganisationScreenState extends State<CreateOrganisationScreen> {
  final _formKey = GlobalKey<FormState>();
  static final SharedPreferencesService shareP = SharedPreferencesService();
  Organisation _organisation = Organisation();
  List<Member> _members = []; // TODO create this list later from membersID
  String _locale = 'fr';
  DateFormat format = DateFormat('EEEE dd MMMM à HH:mm');
  File _imageFile;
  DatabaseService _database = DatabaseService();
  List<Profile> _profiles;

  @override
  void initState() {
    super.initState();

    initializeDateFormatting(_locale, null).then((_) {
      setState(() {
        format = DateFormat('EEEE dd MMMM à HH:mm', _locale);
      });
    });
    getProfiles();
    Member creaMember = Member.fromUserID(widget.userID);
    creaMember.role = 'Owner';
    _members.add(creaMember);
  }

  void getProfiles() async {
    List<Profile> profiles = await _database.getProfileList();
    setState(() {
      _profiles = profiles;
    });
  }

  List<Profile> filterProfiles(String pattern) {
    return _profiles.where((profile) {
      return profile
          .getFullName()
          .toLowerCase()
          .contains(pattern.toLowerCase());
    }).toList();
  }

  Profile getProfile(String userID) {
    if (_profiles != null)
      return _profiles.singleWhere((profile) => profile.id == userID); // 3
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: Text('Créer une organisation'),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                showAvatar(),
                showPickAvatarButton(),
                showNameField(),
                showDescriptionField(),
                SizedBox(
                  height: 16.0,
                ),
                Text(
                  'Membres',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                showSelectedMembers(),
                showAddMemberButton(),
                showSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget showAvatar() {
    if (_imageFile != null) {
      return Center(
        child: InkWell(
          onTap: () => _showSelectPictureMenu(),
          child: CircleAvatar(
            radius: 60.0,
            backgroundImage: FileImage(_imageFile),
          ),
        ),
      );
    } else {
      return Center(
        child: InkWell(
            onTap: () => _showSelectPictureMenu(),
            child: _organisation.getCircleAvatar()),
      );
    }
  }

  Widget showPickAvatarButton() {
    return Center(
      child: FlatButton(
        onPressed: () => _showSelectPictureMenu(),
        child: Text(
          'Changer de photo',
          style: TextStyle(color: Colors.blue.shade800),
        ),
      ),
    );
  }

  Future<void> _showSelectPictureMenu() {
    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Changer de photo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FlatButton.icon(
                  label: Text(
                    'Importer depuis la gallerie',
                    style: TextStyle(color: Colors.blue.shade800),
                  ),
                  icon: Icon(
                    Icons.photo_library,
                    color: Colors.blue.shade800,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                FlatButton.icon(
                  label: Text('Prendre une photo',
                      style: TextStyle(color: Colors.blue.shade800)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                  icon: Icon(
                    Icons.photo_camera,
                    color: Colors.blue.shade800,
                  ),
                ),
                FlatButton.icon(
                  label: Text('Supprimer la photo',
                      style: TextStyle(color: Colors.red.shade800)),
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red.shade800,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _clearImage();
                  },
                ),
              ],
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Fermer'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  Widget showNameField() {
    return TextFormField(
      onSaved: (String value) {
        _organisation.fullName = value;
      },
      onChanged: (String text) {
        setState(() {
          _organisation.fullName = text;
        });
      },
      decoration: const InputDecoration(
        labelText: "Nom de l'organisation",
      ),
      validator: (value) {
        if (value.isEmpty) {
          return 'Le nom ne peut pas être vide';
        }
        return null;
      },
    );
  }

  Widget showDescriptionField() {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: TextFormField(
        minLines: 2,
        maxLines: 5,
        cursorColor: Colors.blue.shade800,
        onSaved: (String value) {
          _organisation.description = value;
        },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          helperText: "Présente ton organisation",
          labelText: 'Description',
        ),
      ),
    );
  }

  Widget showAddImageField() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      decoration: BoxDecoration(
        border: Border.all(
            color: _imageFile != null ? Colors.blue.shade800 : Colors.grey,
            width: _imageFile != null ? 3.0 : 1.0),
        borderRadius: BorderRadius.all(
          Radius.circular(5.0),
        ),
      ),
      child: Column(
        children: <Widget>[
          Text(
            'Ajouter une image',
            style: TextStyle(fontSize: 18.0),
          ),
          showImagePickerButtons(),
          if (_imageFile != null) showSelectedImage(),
        ],
      ),
    );
  }

  Widget showImagePickerButtons() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(
            Icons.photo_camera,
            size: 30,
          ),
          onPressed: () => _pickImage(ImageSource.camera),
          color: Colors.blue.shade800,
        ),
        IconButton(
          icon: Icon(
            Icons.photo_library,
            size: 30,
          ),
          onPressed: () => _pickImage(ImageSource.gallery),
          color: Colors.amber.shade800,
        ),
      ],
    );
  }

  Widget showSelectedImage() {
    return Column(children: <Widget>[
      Image.file(_imageFile),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          FlatButton(
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)),
            color: Colors.blue.shade800,
            child: Icon(Icons.crop, color: Colors.white),
            onPressed: _cropImage,
          ),
          FlatButton(
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)),
            color: Colors.red.shade800,
            child: Icon(
              Icons.delete_forever,
              color: Colors.white,
            ),
            onPressed: _clearImage,
          ),
        ],
      ),
    ]);
  }

  Future<void> _cropImage() async {
    File cropped = await ImageCropper.cropImage(
      sourcePath: _imageFile.path,
      cropStyle: CropStyle.circle,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
      ],
      androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Recadrer',
          toolbarColor: Colors.blue.shade800,
          activeWidgetColor: Colors.blue.shade800,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: Colors.amber.shade800,
          initAspectRatio: CropAspectRatioPreset.original,
          hideBottomControls: true,
          lockAspectRatio: true),
      iosUiSettings: IOSUiSettings(
        title: 'Recadrer',
        doneButtonTitle: 'Valider',
        cancelButtonTitle: 'Retour',
        minimumAspectRatio: 1.0,
      ),
    );

    setState(() {
      _imageFile = cropped ?? _imageFile;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    File selected =
        await ImagePicker.pickImage(source: source, imageQuality: 50);
    if (selected != null) {
      setState(() {
        _imageFile = selected;
        _cropImage();
      });
    }
  }

  void _clearImage() {
    setState(() => _imageFile = null);
  }

  Widget showAddMemberButton() {
    return Center(
      child: OutlineButton.icon(
        onPressed: () => {showSelectMemberDialog()},
        icon: Icon(
          Icons.add,
          color: Colors.blue.shade800,
        ),
        label: Text('Ajouter des membres'),
      ),
    );
  }

  Widget showSelectedMembers() {
    if (_members != null && _members.length > 0) {
      return Container(
        child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _members.length,
            itemBuilder: (BuildContext context, int index) {
              Profile profile = getProfile(_members[index].userID);
              if (profile == null) {
                return Text('Chargement...');
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: InkWell(
                  onTap: () {
                    showEditMemberDialog(index, profile);
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      profile.getCircleAvatar(radius: 40.0),
                      SizedBox(
                        width: 8.0,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                                profile.getFullName() + ' (P${profile.promo})'),
                            Text(_members[index].position),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 8.0,
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _members[index].role,
                          icon: Icon(Icons.arrow_drop_down),
                          onChanged: (String newValue) {
                            setState(() {
                              _members[index].role = newValue;
                            });
                          },
                          items: createDropdownMenuItemList(Member.roles),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
      );
    } else {
      return Center(
        child: Text('Pas de membre sélectionné'),
      );
    }
  }

  Future<void> showSelectMemberDialog() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        if (_profiles != null && _profiles.length > 0) {
          List<Profile> profileFiltered = _profiles;
          return StatefulBuilder(builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Ajouter des membres'),
              content: Column(
                children: <Widget>[
                  TextField(
                    onChanged: (pattern) {
                      setStateDialog(() {
                        profileFiltered = filterProfiles(pattern);
                      });
                    },
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: "Entrer un nom...",
                      labelText: 'Rechercher un étudiant',
                      prefixIcon: Icon(
                        Icons.search,
                        size: 24.0,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 8.0,
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: profileFiltered.length,
                      itemBuilder: (BuildContext context, int index) {
                        Profile profile = profileFiltered[index];
                        return InkWell(
                          onTap: () {
                            setStateDialog(() {});
                            setState(() {
                              if (containsValue(
                                  _members, 'userID', profile.id)) {
                                _members.removeWhere(
                                    (member) => member.userID == profile.id);
                              } else {
                                Member newMember =
                                    Member.fromUserID(profile.id);
                                _members.add(newMember);
                              }
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              profile.getCircleAvatar(radius: 35.0),
                              SizedBox(
                                width: 8.0,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      profile.getFullName(),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text('P${profile.promo}'),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 16.0,
                                child: Checkbox(
                                    activeColor: Colors.blue.shade800,
                                    value: containsValue(
                                        _members, 'userID', profile.id),
                                    onChanged: (bool value) {
                                      setStateDialog(() {});
                                      setState(() {
                                        if (containsValue(
                                            _members, 'userID', profile.id)) {
                                          _members.removeWhere((member) =>
                                              member.userID == profile.id);
                                        } else {
                                          Member newMember =
                                              Member.fromUserID(profile.id);
                                          _members.add(newMember);
                                        }
                                      });
                                    }),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text('Fermer'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
        } else {
          return Container(
            child: Text('Chargement...'),
          );
        }
      },
    );
  }

  Future<void> showEditMemberDialog(int indexInMembers, Profile profile) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Modifier un membre'),
            content: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  profile.getCircleAvatar(radius: 50.0),
                  Text(profile.getFullName()),
                  Text('P${profile.promo}'),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Position',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14.0),
                    ),
                  ),
                  TextField(
                    decoration: const InputDecoration(
                        labelText: "Position dans l'organisation",
                        hintText: 'Président, trésorier, VP...'),
                    onChanged: (text) {
                      setState(() {
                        _members[indexInMembers].position = text;
                      });
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rôle (Permissions)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14.0),
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _members[indexInMembers].role,
                      icon: Icon(Icons.arrow_drop_down),
                      onChanged: (String newValue) {
                        setStateDialog(() {});
                        setState(() {
                          _members[indexInMembers].role = newValue;
                        });
                      },
                      items: createDropdownMenuItemList(Member.roles),
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Fermer'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
      },
    );
  }

  Widget showSubmitButton() {
    return new Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
        child: SizedBox(
          height: 40.0,
          child: RaisedButton(
            elevation: 4.0,
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)),
            color: Colors.blue.shade800,
            textColor: Colors.white,
            onPressed: () {
              // Validate returns true if the form is valid, or false
              // otherwise.

              if (_formKey.currentState.validate()) {
                _formKey.currentState.save();
                uploadDataToFirebase();
                Navigator.pop(context);
              }
            },
            child: Text(
              "Créer l'organisation",
              style: TextStyle(fontSize: 16.0),
            ),
          ),
        ),
      ),
    );
  }

  void uploadDataToFirebase() async {
    print('SENDING DATA TO FIRESTORE');
    print(_organisation);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _organisation.creatorID = prefs.getString('userID');

    DatabaseService database = DatabaseService();
    database.createOrganisationAndMembers(_organisation, _members, _imageFile);
  }
}

bool containsValue(List<dynamic> list, String attribute, var value) {
  var itemSearched =
      list.firstWhere((item) => item[attribute] == value, orElse: () => null);
  if (itemSearched == null) {
    return false;
  } else {
    return true;
  }
}

List<DropdownMenuItem<String>> createDropdownMenuItemList(Map map) {
  List<DropdownMenuItem<String>> list = [];
  map.forEach((key, value) {
    list.add(DropdownMenuItem<String>(
      value: key,
      child: Text(value),
    ));
  });
  return list;
}