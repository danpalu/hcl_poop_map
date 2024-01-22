// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:core';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'themes.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://avgzuzegwdshhzseszkf.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF2Z3p1emVnd2RzaGh6c2VzemtmIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTcxMTA4MTksImV4cCI6MjAxMjY4NjgxOX0.Nlm5I3i0h26N3fzMSmgfqF5ubVbsU9JZwqf3GgXmKR8",
  );
  lastPosition = await getLastLocation();

  runApp(const MainApp());
}

final supabase = Supabase.instance.client;
late Account currentUser;
List<Account> follows = List.empty(growable: true);
List<Poop> friendsPoop = List.empty(growable: true);
LatLng lastPosition = LatLng(0, 0);
List<Marker> poopMarkers = List.empty(growable: true);
int selectedView = 0;
int selectedPage = 0;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<bool> checkLogIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool("loggedIn") ?? false;
    if (loggedIn) {
      currentUser = await getLocalUser();
      follows = await getFollows(currentUser);
    }
    log(loggedIn.toString());
    await Future.delayed(Duration(milliseconds: 500));
    return loggedIn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).canvasColor,
        body: FutureBuilder(
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data ?? false) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: ((context, animation, secondaryAnimation) =>
                          HomePage()),
                      transitionDuration: Duration(milliseconds: 800),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.ease;

                        final tween = Tween(begin: begin, end: end);
                        final curvedAnimation = CurvedAnimation(
                          parent: animation,
                          curve: curve,
                        );

                        return FadeTransition(
                          opacity: curvedAnimation,
                          child: child,
                        );
                        return SlideTransition(
                          position: tween.animate(curvedAnimation),
                          child: child,
                        );
                      },
                    ),
                  );
                });
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: ((context, animation, secondaryAnimation) =>
                          Login()),
                      transitionDuration: Duration(milliseconds: 800),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.ease;

                        final tween = Tween(begin: begin, end: end);
                        final curvedAnimation = CurvedAnimation(
                          parent: animation,
                          curve: curve,
                        );

                        return FadeTransition(
                          opacity: curvedAnimation,
                          child: child,
                        );
                        return SlideTransition(
                          position: tween.animate(curvedAnimation),
                          child: child,
                        );
                      },
                    ),
                  );
                });
              }
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  TitleIcon(),
                  TitleText(),
                  Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: CircularProgressIndicator(),
                  ),
                ],
              ),
            );
          },
          future: checkLogIn(),
        ));
  }
}

class TitleIcon extends StatelessWidget {
  const TitleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "titleText",
      child: Text(
        "💩",
        style: Theme.of(context).textTheme.headlineMedium,
        textScaleFactor: 3,
      ),
    );
  }
}

class TitleText extends StatelessWidget {
  const TitleText({super.key});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "titleIcon",
      child: Text(
        "Poop Map",
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}

class Login extends StatefulWidget {
  const Login({
    super.key,
  });

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String username = "";
  String password = "";
  bool usernameError = false;
  bool passwordError = false;

  final formkey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TitleIcon(),
            TitleText(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 80, vertical: 24),
              child: Form(
                key: formkey,
                child: Column(
                  children: [
                    TextFormField(
                      validator: (value) {
                        if (usernameError) {
                          return "Username with name \"$value\" does not exists";
                        }
                      },
                      onChanged: (value) => setState(() {
                        username = value;
                      }),
                      decoration: InputDecoration(
                        labelText: "Username",
                      ),
                    ),
                    TextFormField(
                      validator: (value) {
                        if (passwordError) return "Wrong password";
                      },
                      onChanged: (value) => setState(() {
                        password = value;
                      }),
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: "Password",
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: FilledButton(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          try {
                            currentUser = await logIn(username, password);
                          } catch (e) {
                            if (await isUsernameRight(username)) {
                              setState(() {
                                usernameError = false;
                                passwordError = true;
                              });
                            } else {
                              setState(() {
                                usernameError = true;
                                passwordError = true;
                              });
                            }
                            formkey.currentState!.validate();
                            return;
                          }
                          await saveLogIn();
                          await localSaveUser(currentUser);
                          follows = await getFollows(currentUser);

                          navigator.pushReplacement(
                            PageRouteBuilder(
                              pageBuilder:
                                  ((context, animation, secondaryAnimation) =>
                                      HomePage()),
                              transitionDuration: Duration(milliseconds: 500),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.ease;

                                final tween = Tween(begin: begin, end: end);
                                final curvedAnimation = CurvedAnimation(
                                  parent: animation,
                                  curve: curve,
                                );

                                // return FadeTransition(
                                //   opacity: curvedAnimation,
                                //   child: child,
                                // );
                                return SlideTransition(
                                  position: tween.animate(curvedAnimation),
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: const Text("Login"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 24,
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => NewUser()));
              },
              child: Text("Register new user"),
            )
          ],
        ),
      ),
    );
  }
}

class NewUser extends StatefulWidget {
  const NewUser({super.key});

  @override
  State<NewUser> createState() => _NewUserState();
}

class _NewUserState extends State<NewUser> {
  String username = "";
  String password = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("New User")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TitleIcon(),
            TitleText(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 80, vertical: 24),
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) => setState(() {
                      username = value;
                    }),
                    decoration: InputDecoration(
                      labelText: "Username",
                    ),
                  ),
                  TextField(
                    onChanged: (value) => setState(() {
                      password = value;
                    }),
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: "Password",
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                currentUser = await newUser(username, password);
                await localSaveUser(currentUser);
                follows = await getFollows(currentUser);

                navigator.popUntil((route) => route.isFirst);
                navigator.pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: ((context, animation, secondaryAnimation) =>
                        HomePage()),
                    transitionDuration: Duration(milliseconds: 500),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.ease;

                      final tween = Tween(begin: begin, end: end);
                      final curvedAnimation = CurvedAnimation(
                        parent: animation,
                        curve: curve,
                      );

                      // return FadeTransition(
                      //   opacity: curvedAnimation,
                      //   child: child,
                      // );
                      return SlideTransition(
                        position: tween.animate(curvedAnimation),
                        child: child,
                      );
                    },
                  ),
                );
                navigator.popUntil((route) => route.isFirst);
              },
              child: const Text("Create new user"),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: selectedPage == 1
          ? AppBar(
              title: DropdownMenu(
                onSelected: (value) {
                  setState(() {
                    selectedView = value!;
                  });
                },
                initialSelection: selectedView,
                enableSearch: false,
                leadingIcon:
                    selectedView == 0 ? Icon(Icons.group) : Icon(Icons.public),
                inputDecorationTheme:
                    InputDecorationTheme(border: InputBorder.none),
                dropdownMenuEntries: [
                  DropdownMenuEntry(
                    value: 0,
                    label: "Friends only",
                    leadingIcon: Icon(Icons.group),
                  ),
                  DropdownMenuEntry(
                    value: 1,
                    label: "Everyone",
                    leadingIcon: Icon(Icons.public),
                  ),
                ],
              ),
            )
          : AppBar(title: Text("Poop Map 💩"), centerTitle: true),
      body: switch (selectedPage) {
        0 => HomeFeed(),
        1 => MapView(),
        2 => Profile(),
        int() => null,
      },
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.map), label: "Map"),
          NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: selectedPage,
        onDestinationSelected: (value) => setState(() {
          if (selectedPage == 1) poopMarkers.clear();
          selectedPage = value;
        }),
      ),
      floatingActionButton: selectedPage == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                setState(() {
                  isLoading = true;
                });
                final navigator = Navigator.of(context);
                lastPosition = await getLastLocation();
                await navigator.push(
                  MaterialPageRoute(
                    builder: (context) => AddPoop(),
                  ),
                );
              },
              label: Text("Add poop"),
              icon: Icon(Icons.add),
            ),
    );
  }
}

class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.group),
                Text(
                  " Friends' poops",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            IconButton(onPressed: () {}, icon: Icon(Icons.arrow_forward))
          ],
        ),
      ),
      FutureBuilder(
        future: getFriendsPoops(currentUser, follows),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            friendsPoop = snapshot.data!;
            final List<Widget> list = List.empty(growable: true);
            const numberShown = 8;
            final length = (friendsPoop.length < numberShown)
                ? friendsPoop.length
                : numberShown;
            for (var i = 0; i < length; i++) {
              final temp = friendsPoop[i];
              final newPoopCard = PoopCard(poop: temp);
              list.add(newPoopCard);
            }

            return Column(
              children: list,
            );
          }
          return PoopCard(
            poop: Poop(
              LatLng(0, 0),
              0,
              Account(0, "", ""),
              DateTime.now(),
            ),
          );
        },
      ),
    ]);
  }
}

class PoopCard extends StatelessWidget {
  const PoopCard({
    super.key,
    required this.poop,
  });

  final Poop poop;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShowPoopDetails(poop: poop),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_4,
                    size: 70,
                  ),
                  SizedBox(
                    width: 12,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(timeAgo(poop.time)),
                      Text(poop.user.displayname),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  for (int i = 0; i < 5; i++)
                    (i < poop.rating)
                        ? Icon(
                            Icons.star,
                            color: Colors.amber,
                          )
                        : Icon(
                            Icons.star_border,
                            color: Colors.amber,
                          )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: selectedView == 0
          ? getFriendsPoops(currentUser, follows)
          : getPoops(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          poopMarkers.clear();
          friendsPoop = snapshot.data!;
          for (var element in friendsPoop) {
            poopMarkers.add(
              Marker(
                point: element.location,
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      showDragHandle: true,
                      context: context,
                      builder: (context) {
                        return SizedBox(
                          height: 220,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_3, size: 75),
                                  Text(element.user.username),
                                  Text(timeAgo(element.time)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (int i = 0; i < 5; i++)
                                        (i < element.rating)
                                            ? Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                              )
                                            : Icon(
                                                Icons.star_border,
                                                color: Colors.amber,
                                              )
                                    ],
                                  ),
                                  Expanded(
                                    child: SizedBox(),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        icon: Icon(Icons.close),
                                        label: Text("Close"),
                                      ),
                                      FilledButton.icon(
                                        onPressed: () async {
                                          await newFollow(
                                              currentUser, element.user.uid);
                                        },
                                        icon: Icon(Icons.person_add),
                                        label: Text("Follow"),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Center(
                    child: Text(
                      "💩",
                      textScaleFactor: 2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                height: 50,
                width: 50,
              ),
            );
          }
          return FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(57, 10),
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  maxNativeZoom: 20,
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  fallbackUrl: "",
                ),
                MarkerLayer(markers: poopMarkers)
              ]);
        }
        return SizedBox.expand(
          child: ColoredBox(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("${currentUser.displayname}#${currentUser.uid}"),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Follows: "),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => AddFollow()))
                    .then((value) => setState(
                          () {},
                        ));
              },
              icon: Icon(Icons.add),
              label: Text("Add follow"),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: follows.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: ListTile(
                  title: Text(follows[index].displayname),
                  subtitle:
                      Text("${follows[index].username} #${follows[index].uid}"),
                ),
              );
            },
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await logOut();
                navigator.pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => Login(),
                  ),
                );
              },
              child: Text("Log out"),
            ),
          ),
        ),
      ],
    );
  }
}

class AddFollow extends StatefulWidget {
  const AddFollow({super.key});

  @override
  State<AddFollow> createState() => _AddFollowState();
}

class _AddFollowState extends State<AddFollow> {
  String newFollowID = "";
  String searchName = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New follow"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
            setState(() {
              follows;
            });
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("Add by #:"),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("#"),
              SizedBox(
                width: 50,
                child: TextField(
                  onChanged: (value) => setState(() {
                    newFollowID = value;
                  }),
                  maxLength: 5,
                  decoration: InputDecoration(counterText: ""),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  keyboardType: TextInputType.number,
                ),
              ),
              IconButton.outlined(
                onPressed: () async {
                  final scaffold = ScaffoldMessenger.of(context);

                  try {
                    await newFollow(currentUser, int.parse(newFollowID));
                  } catch (e) {
                    scaffold.showSnackBar(
                      SnackBar(
                        content: Text("Something went wrong"),
                      ),
                    );
                  }
                  final temp = await getFollows(currentUser);
                  setState(() {
                    follows = temp;
                  });
                },
                icon: Icon(Icons.add),
              ),
            ],
          ),
          Divider(),
          SizedBox(
            width: 300,
            child: TextField(
              onChanged: (value) => setState(() {
                searchName = value;
              }),
              decoration: InputDecoration(
                label: Text("Username"),
                suffixIcon: Icon(
                  Icons.search,
                ),
              ),
            ),
          ),
          searchName.isEmpty
              ? Text("Enter a username above to search")
              : FutureBuilder(
                  future: searchUsers(searchName),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data!.isEmpty) {
                        return Text("No matches");
                      }
                      return Expanded(
                        child: ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final acc = snapshot.data![index];
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Material(
                                child: ListTile(
                                  title: Text("${acc.username}#${acc.uid}"),
                                  tileColor: Colors.amber[100],
                                  trailing: (follows.any(
                                          (element) => element.uid == acc.uid))
                                      ? IconButton.outlined(
                                          onPressed: () {},
                                          icon: Icon(Icons.check),
                                        )
                                      : IconButton.filledTonal(
                                          icon: Icon(Icons.add),
                                          onPressed: () async {
                                            await newFollow(
                                                currentUser, acc.uid);
                                            final temp =
                                                await getFollows(currentUser);
                                            setState(() {
                                              follows = temp;
                                            });
                                          },
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }
                    return CircularProgressIndicator();
                  },
                )
        ],
      ),
    );
  }
}

class AddPoop extends StatefulWidget {
  const AddPoop({super.key});

  @override
  State<AddPoop> createState() => _AddPoopState();
}

class _AddPoopState extends State<AddPoop> {
  int poopRating = 3;
  LatLng poopPosition = LatLng(0, 0);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add poop 💩"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                height: 200,
                child: FutureBuilder(
                  future: getPosition(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      poopPosition = LatLng(
                          snapshot.data!.latitude, snapshot.data!.longitude);
                      return FlutterMap(
                          options: MapOptions(
                            interactionOptions: InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                            initialCenter: lastPosition,
                            initialZoom: 15,
                          ),
                          children: [
                            TileLayer(
                              maxNativeZoom: 20,
                              urlTemplate:
                                  "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                              fallbackUrl: "",
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: lastPosition,
                                  width: 80,
                                  height: 80,
                                  child: Text("💩",
                                      textScaleFactor: 2,
                                      textAlign: TextAlign.center),
                                ),
                              ],
                            ),
                          ]);
                    }
                    return SizedBox.expand(
                      child: ColoredBox(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  },
                )),
          ),
          Text("Rating:"),
          RatingBar(
            initialRating: poopRating.toDouble(),
            glow: false,
            allowHalfRating: false,
            minRating: 1,
            tapOnlyMode: false,
            ratingWidget: RatingWidget(
              full: Icon(
                Icons.star,
                color: Colors.amber,
              ),
              half: Icon(
                Icons.star_half,
                color: Colors.amber,
              ),
              empty: Icon(
                Icons.star_outline,
                color: Colors.amber,
              ),
            ),
            onRatingUpdate: (rating) {
              setState(() {
                poopRating = rating.toInt();
              });
            },
          ),
          Expanded(child: SizedBox()),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton(
              onPressed: () async {
                final nagivator = Navigator.of(context);
                Poop newPoop = Poop(
                  poopPosition,
                  poopRating,
                  currentUser,
                  DateTime.now(),
                );
                await addPoop(newPoop);
                setState(() {
                  friendsPoop.add(newPoop);
                });
                nagivator.pop();
              },
              child: Text("Save"),
            ),
          ),
        ],
      ),
    );
  }
}

class ShowPoopDetails extends StatefulWidget {
  const ShowPoopDetails({super.key, required this.poop});
  final Poop poop;

  @override
  State<ShowPoopDetails> createState() => _ShowPoopDetailsState();
}

class _ShowPoopDetailsState extends State<ShowPoopDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.poop.user.displayname}'s poop"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              height: 400,
              child: FlutterMap(
                options: MapOptions(
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                  initialCenter: widget.poop.location,
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    maxNativeZoom: 20,
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    fallbackUrl: "",
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: widget.poop.location,
                        width: 80,
                        height: 80,
                        child: Text("💩",
                            textScaleFactor: 2, textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < 5; i++)
                  (i < widget.poop.rating)
                      ? Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 50,
                        )
                      : Icon(
                          Icons.star_border,
                          color: Colors.amber,
                          size: 50,
                        )
              ],
            ),
          ),
          Text(
            timeAgo(widget.poop.time),
          ),
          Expanded(child: SizedBox()),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Does not work yet :((()))"),
                    ),
                  );
                  Navigator.pop(context);
                });
              },
              label: Text("Show on map"),
              icon: Icon(Icons.map),
            ),
          ),
        ],
      ),
    );
  }
}
