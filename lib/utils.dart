import 'package:hcl_poop_map/main.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Account {
  int uid;
  String username;
  String displayname;

  Account(this.uid, this.username, this.displayname);
}

class Poop {
  LatLng location;
  int rating;
  Account user;
  DateTime time;

  Poop(this.location, this.rating, this.user, this.time);
}

Future<Account> newUser(String username, String password) async {
  var user = await supabase.from("users").insert({
    "username": username,
    "password": password,
    "displayname": username
  }).select();
  Account acc =
      Account(user[0]["uid"], user[0]["username"], user[0]["displayname"]);
  return acc;
}

Future<void> localSaveUser(Account currentUser) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt("uid", currentUser.uid);
  prefs.setString("username", currentUser.username);
  prefs.setString("displayname", currentUser.displayname);
  prefs.setBool("loggedIn", true);
}

Future<Account> getLocalUser() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int uid = prefs.getInt("uid") ?? 0;
  String uname = prefs.getString("username") ?? "";
  String dname = prefs.getString("displayname") ?? "";
  return Account(uid, uname, dname);
}

Future<void> logOut() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool("loggedIn", false);
}

Future<void> saveLogIn() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool("loggedIn", true);
}

Future<Account> logIn(String username, String password) async {
  final data = await supabase
      .from("users")
      .select()
      .eq("username", username)
      .eq("password", password)
      .select();

  final acc =
      Account(data[0]["uid"], data[0]["username"], data[0]["displayname"]);

  return acc;
}

Future<bool> isUsernameRight(String username) async {
  try {
    final data =
        await supabase.from("users").select().eq("username", username).select();
    data[0];
  } catch (e) {
    return false;
  }
  return true;
}

Future<List<Account>> getFollows(Account user) async {
  List<Account> follows = List.empty(growable: true);
  final data = await supabase.from("follows_view").select().eq("uid", user.uid);
  for (var user in data) {
    follows.add(Account(
        user["followuid"], user["followusername"], user["followdisplayname"]));
  }

  return follows;
}

Future<void> newFollow(Account currentUser, int newFollow) async {
  await supabase
      .from("follows")
      .insert({"uid": currentUser.uid, "fid": newFollow});
}

Future<List<Account>> searchUsers(String search) async {
  List<Account> follows = List.empty(growable: true);
  await Future.delayed(
    Duration(milliseconds: 500),
  );
  final data =
      await supabase.from("users").select().ilike("username", "%$search%");
  for (var user in data) {
    follows.add(Account(user["uid"], user["username"], user["displayname"]));
  }

  return follows;
}

Future<void> addPoop(Poop poop) async {
  await supabase.from("poops").insert({
    "lat": poop.location.latitude,
    "lon": poop.location.longitude,
    "rating": poop.rating,
    "uid": poop.user.uid
  });
}

Future<List<Poop>> getPoops() async {
  List<Poop> poops = List.empty(growable: true);
  final data = await supabase.from("poops_view").select();
  for (var poop in data) {
    final temp = Poop(
        LatLng(
          (poop["lat"] + 0.0),
          (poop["lon"] + 0.0),
        ),
        poop["rating"],
        Account(poop["uid"], poop["username"], poop["displayname"]),
        DateTime.parse(poop["time"]));
  }

  return poops;
}
