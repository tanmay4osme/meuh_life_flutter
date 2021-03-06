import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meuh_life/models/Member.dart';
import 'package:meuh_life/models/Organisation.dart';
import 'package:meuh_life/models/Profile.dart';
import 'package:meuh_life/services/DatabaseService.dart';
import 'package:meuh_life/services/utils.dart';

class EditOrganisationScreen extends StatefulWidget {
  EditOrganisationScreen({this.userID, this.organisation});

  final String userID;
  final Organisation organisation;

  @override
  _EditOrganisationScreenState createState() => _EditOrganisationScreenState();
}

class _EditOrganisationScreenState extends State<EditOrganisationScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Member> _members = [];
  Organisation _organisation;
  File _imageFile;
  DatabaseService _database = DatabaseService();
  List<Profile> _profiles;
  List<String> _memberIDToRemove = [];

  @override
  void initState() {
    super.initState();
    _organisation = widget.organisation;
    getMembers();
    getProfiles();
  }

  void getMembers() async {
    List<Member> members = await _database.getMemberList(
        on: 'organisationID', onValueEqualTo: widget.organisation.id);
    setState(() {
      _members = members;
    });
  }

  void getProfiles() async {
    List<Profile> profiles = await _database.getProfileList();
    setState(() {
      _profiles = profiles;
    });
  }

  List<Profile> filterProfiles(String pattern) {
    return _profiles.where((profile) {
      return profile.fullName.toLowerCase().contains(pattern.toLowerCase());
    }).toList();
  }

  Profile getProfile(String userID) {
    if (_profiles != null)
      return _profiles.singleWhere((profile) => profile.id == userID);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: Text('Modifier une organisation'),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                  ),
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
            child: widget.organisation.getCircleAvatar()),
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
      initialValue: _organisation.fullName,
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
        initialValue: _organisation.description,
        minLines: 2,
        maxLines: null,
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
        onPressed: () => {showAddMemberDialog()},
        icon: Icon(
          Icons.add,
          color: Colors.blue.shade800,
        ),
        label: Text('Ajouter des membres'),
      ),
    );
  }

  Widget showSelectedMembers() {
    Map rolesWithoutOwner = Map.from(Member.roles);
    rolesWithoutOwner.removeWhere((key, value) => key == 'Owner');
    if (_members != null && _members.length > 0) {
      Member currentMember = _members
          .firstWhere((Member member) => member.userID == widget.userID);
      bool isAdmin = currentMember.role == 'Admin';
      bool isOwner = currentMember.role == 'Owner';
      return Container(
        child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _members.length,
            itemBuilder: (BuildContext context, int index) {
              bool isCurrentUser = _members[index].userID == widget.userID;
              Profile profile = getProfile(_members[index].userID);
              if (profile == null) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              return Card(
                color: _members[index].state == 'Requested'
                    ? Colors.amber.shade400
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      profile.getCircleAvatar(radius: 24.0),
                      SizedBox(
                        width: 8.0,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (_members[index].state == 'Requested')
                              Text("Souhaite rejoindre l'organisation"),
                            Text(
                              profile.fullName + ' (P${profile.promo})',
                              style: TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.bold),
                            ),
                            TextFormField(
                              initialValue: _members[index].position,
                              decoration: const InputDecoration(
                                labelText: "Position dans l'organisation",
                                hintText: 'Président, trésorier, VP...',
                              ),
                              onChanged: (text) {
                                setState(() {
                                  _members[index].position = text;
                                });
                              },
                            ),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                disabledHint:
                                    Text(Member.roles[_members[index].role]),
                                value: _members[index].role,
                                icon: Icon(Icons.arrow_drop_down),
                                onChanged: (String newValue) {
                                  setState(() {
                                    _members[index].role = newValue;
                                  });
                                },
                                items: (isOwner || isAdmin) &&
                                        !isCurrentUser &&
                                        (_members[index].role != 'Owner')
                                    ? createDropdownMenuItemList(isAdmin
                                        ? rolesWithoutOwner
                                        : Member.roles)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),

                      //TODO: Show this icon only if allow
                      if (_members[index].role != 'Owner' && !isCurrentUser)
                        IconButton(
                          onPressed: () {
                            String memberID = getMixKey(
                                _members[index].userID, widget.organisation.id);
                            print('REMOVE $memberID');
                            if (!_memberIDToRemove.contains(memberID))
                              _memberIDToRemove.add(memberID);
                            print('REMOVE ${_memberIDToRemove.toString()}');
                            setState(() {
                              _members.removeAt(index);
                            });
                          },
                          icon: Icon(
                            Icons.delete,
                            color: Colors.grey,
                          ),
                        ),
                      if (_members[index].state == 'Requested')
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _members[index].state = 'Accepted';
                              _members[index].addedBy = widget.userID;
                              _members[index].joiningDate = DateTime.now();
                            });
                            print('accepder');
                          },
                          icon: Icon(
                            Icons.check,
                            color: Colors.green,
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

  Future<void> showAddMemberDialog() {
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
                        if (profile.id == widget.userID) return Container();
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
                                newMember.organisationID = _organisation.id;
                                newMember.addedBy = widget.userID;
                                newMember.joiningDate = DateTime.now();
                                newMember.state = 'Accepted';
                                _members.add(newMember);
                              }
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              profile.getCircleAvatar(radius: 24.0),
                              SizedBox(
                                width: 8.0,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      profile.fullName,
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
                                          newMember.organisationID =
                                              _organisation.id;
                                          newMember.addedBy = widget.userID;
                                          newMember.joiningDate =
                                              DateTime.now();
                                          newMember.state = 'Accepted';
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
                removeMembers();
                Navigator.pop(context);
              }
            },
            child: Text(
              "Enregistrer les changements",
              style: TextStyle(fontSize: 16.0),
            ),
          ),
        ),
      ),
    );
  }

  void removeMembers() async {
    if (_memberIDToRemove.length > 0) {
      //Remove duplicates memberIDs
      _memberIDToRemove = _memberIDToRemove.toSet().toList();

      //Remove IDs that were added again
      List<String> newMemberID = _members
          .map((Member member) =>
              getMixKey(member.userID, member.organisationID))
          .toList();
      _memberIDToRemove = _memberIDToRemove
          .where((memberID) => !newMemberID.contains(memberID))
          .toList();

      _memberIDToRemove.forEach((String memberID) {
        _database.deleteMember(memberID);
      });
    }
  }

  void uploadDataToFirebase() async {
    // TODO: Manage the data update: maybe use a userID/orgaID doumentID key
    DatabaseService database = DatabaseService();
    database.updateOrganisationAndMembers(_organisation, _members, _imageFile);
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
