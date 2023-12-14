import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';
import 'dailyexpenses.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController serverIpController = TextEditingController();

  String currentip = '192.168.0.17';

  @override
  void initState(){
    //TODO: implement initState
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Screen'),
      ),


      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset('assets/daily.png')),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: passwordController,
                  obscureText: true,  //Hide the password
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: serverIpController,
                  decoration: InputDecoration(
                    labelText: "IP address",
                  ),),
              ),

              ElevatedButton(
                onPressed: () async {
                  // Implement login logic here
                  String username = usernameController.text;
                  String password = passwordController.text;
                  if (username == 'test' && password == '123456789'){
                    //Navigate to the daily expense screen
                    final prefs = await SharedPreferences.getInstance();
                    if (serverIpController.text.isEmpty)
                    {
                      String ip = currentip;
                      await prefs.setString("ip", ip);
                    }
                    else{
                      String ip = serverIpController.text;
                      await prefs.setString("ip", ip);
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DailyExpensesApp(username:username),
                      ),
                    );
                  }else{
                    //show an error message or handle invalid login
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Login Failed'),
                          content: const Text('Invalid username or password.'),
                          actions: [
                            TextButton(
                              child: const Text('OK'),
                              onPressed: (){
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: const Text ('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}