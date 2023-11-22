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

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme,
      home: const SplashScreen(),
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
  int selectedPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Poop Map 💩"), centerTitle: true),
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
          selectedPage = value;
        }),
      ),
      floatingActionButton: selectedPage == 2
          ? Container()
          : FloatingActionButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await getPosition();
                lastPosition = await getLastLocation();
                navigator.push(
                  MaterialPageRoute(
                    builder: (context) => AddPoop(),
                  ),
                );
              },
              child: Icon(Icons.add),
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
                Icon(Icons.explore),
                Text(
                  " Explore",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            IconButton(onPressed: () {}, icon: Icon(Icons.arrow_forward))
          ],
        ),
      ),
      FutureBuilder(
        future: getPoops(),
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
              final poopCard = Card(
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
                              Text(
                                  "${DateTime.now().difference(temp.time).inMinutes} minutes ago"),
                              Text(temp.user.displayname),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          for (int i = 0; i < 5; i++)
                            (i < temp.rating)
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
              );
              list.add(poopCard);
            }

            return Column(
              children: list,
            );
          }
          return CircularProgressIndicator();
        },
      ),
    ]);
  }
}

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
            options: MapOptions(
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
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(57.0469, 9.9431),
                    width: 80,
                    height: 80,
                    child: Text("💩",
                        textScaleFactor: 2, textAlign: TextAlign.center),
                  ),
                ],
              ),
            ]),
        FilledButton(
          onPressed: () async {
            friendsPoop = await getPoops();
          },
          child: Text("Load poop list"),
        ),
      ],
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add poop 💩"),
      ),
      body: Text(lastPosition.toString()),
    );
  }
}
