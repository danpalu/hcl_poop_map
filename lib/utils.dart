import 'package:hcl_poop_map/main.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

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

Future<LatLng> getLastLocation() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  double lat = prefs.getDouble("lat") ?? 0;
  double lon = prefs.getDouble("lon") ?? 0;
  return LatLng(lat, lon);
}

Future<void> saveLastLocation(Position location) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setDouble("lat", location.latitude);
  prefs.setDouble("lon", location.longitude);
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
  final data = await supabase.from("poops_view").select().order("time");
  for (var poop in data) {
    final temp = Poop(
        LatLng(
          (poop["lat"] + 0.0),
          (poop["lon"] + 0.0),
        ),
        poop["rating"],
        Account(poop["uid"], poop["username"], poop["displayname"]),
        DateTime.parse(poop["time"]));
    poops.add(temp);
  }

  return poops;
}

Future<Position> getPosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  final position = await Geolocator.getCurrentPosition();
  saveLastLocation(position);
  return position;
}
