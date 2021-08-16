import 'dart:convert';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ibm_watson/api/speech_api.dart';
import 'package:ibm_watson_assistant/ibm_watson_assistant.dart';
import 'package:flutter_tts/flutter_tts.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var tts = FlutterTts();
  // ignore: non_constant_identifier_names
  Home() async {
    tts.setLanguage('en');
    tts.setPitch(0);
    tts.setSpeechRate(0.5);
  }

  String text = ''; //to store the user's speech as text
  String robotresponse = ''; // store the robot's response as text
  String res = ''; // stores the encoded robot response
  String robot = ''; // store the displayed image path
  String category = ''; // stores the intent of the user's speech
  bool isListening =
  false; // store boolean value weather the bot is listening or not
  final String title = 'Ibm watson assistant'; // the app title

  final auth = IbmWatsonAssistantAuth(
    // the chatbot's credentials
    assistantId: 'fcc2508c-1786-4b2b-8b7b-89ac7f2be024',
    url:
    'https://api.eu-gb.assistant.watson.cloud.ibm.com/instances/3c6ca8de-4e12-4118-bc20-2940c55a8297',
    apikey: 'HSQsJ31vIWRPgeDpNfuKU6lWWTU9-rS7tEQ4rh0BDzNz',
  );

  Future<void> _getChatbotResponse() async {
    try {
      final bot = IbmWatsonAssistant(auth);
      final sessionId = await bot.createSession();
      var botRes = await bot.sendInput(text, sessionId: sessionId);

      res = json.encode(botRes);
      Map<String, dynamic> user =
      jsonDecode(res); //convert the whole response into a map
      category =
      user['output']['intents'][0]['intent']; //get the intent of the text

      if (user['output']['generic'][0]['text'] == null) {
        //if the bot doesn't have a response then throw an exception
        throw ('This is my first custom exception');
      }

      robotresponse = botRes.responseText!; //get the robot response
      tts.speak(robotresponse); //convert robot response from text to audio

    } catch (e) {
      final bot = IbmWatsonAssistant(auth);
      final sessionId = await bot.createSession();
      var botRes = await bot.sendInput("ok", sessionId: sessionId);
      res = json.encode(botRes);
      Map<String, dynamic> user = jsonDecode(res);
      category = user['output']['intents'][0]['intent'];
      robotresponse = botRes.responseText!;
      tts.speak(robotresponse);
    }

    text = '';
    res = '';
    robotresponse = '';
    category = '';
    setState(() {}); //refresh the page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(title),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(robot),
            fit: BoxFit.fill,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        animate: isListening,
        endRadius: 75,
        glowColor: Theme.of(context).primaryColor,
        child: FloatingActionButton(
          child: Icon(isListening ? Icons.mic : Icons.mic_none, size: 36),
          onPressed: toggleRecording,
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future toggleRecording() => SpeechApi.toggleRecording(
    onResult: (text) => setState(() {
      robot = ''; // if the bot is listening change his look to stay still
      setState(() {}); //refresh the page
      this.text = text;
    }),
    onListening: (isListening) {
      tts.stop(); //stop talking if the user is currently talking
      setState(() => this.isListening = isListening);

      if (!isListening) {
        _getChatbotResponse(); //if the user is done talking , go to this function and get the chatbot's response
        tts.setCompletionHandler(() {
          //after the audio is done refresh the page with different robot photo
          setState(() {});
        });
      }
    },
  );
}
