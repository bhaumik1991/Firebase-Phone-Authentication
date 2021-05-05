import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_verification/screens/home_screen.dart';

enum MobileVerificationState{
  SHOW_MOBILE_FORM_STATE,
  SHOW_OTP_FORM_STATE
}

class LogInScreen extends StatefulWidget {
  @override
  _LogInScreenState createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {

  MobileVerificationState currentState = MobileVerificationState.SHOW_MOBILE_FORM_STATE;

  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  FirebaseAuth _auth = FirebaseAuth.instance; // Important

  String verificationId;

  bool showLoading = false;

  void signInWithAuthCredential(PhoneAuthCredential phoneAuthCredential) async{

    setState(() {
      showLoading = true;
    });
    try {
      final authCredential = await _auth.signInWithCredential(phoneAuthCredential);

      setState(() {
        showLoading = false;
      });

      if(authCredential?.user != null){
        Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
      }

    } on FirebaseAuthException catch (e) {
      setState(() {
        showLoading = false;
      });

      // ignore: deprecated_member_use
      _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  getMobileFormWidget(BuildContext context) {
    return Column(
      children: [
        Spacer(),
        TextField(
          controller: phoneController,
          decoration: InputDecoration(
            hintText: "Phone Number"
          ),
        ),
        SizedBox(height: 16,),
        ElevatedButton(
          onPressed: () async{
            setState(() {
              showLoading = true;
            });
             await _auth.verifyPhoneNumber(
                phoneNumber: phoneController.text,

                verificationCompleted: (phoneAuthCredential) async{
                  setState(() {
                    showLoading = false;
                  });
                  //For automatic OTP verification
                  signInWithAuthCredential(phoneAuthCredential);
                },

                verificationFailed: (verificationFailed) async{
                  setState(() {
                    showLoading = false;
                  });
                  // ignore: deprecated_member_use
                  _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(verificationFailed.message)));
                },

                codeSent: (verificationId, resendingToken) async{
                  setState(() {
                    showLoading = false;
                    currentState = MobileVerificationState.SHOW_OTP_FORM_STATE;
                    this.verificationId = verificationId;
                  });
                },

                codeAutoRetrievalTimeout: (verificationId) async{

                },
            );
          },
          child: Text("SEND VERIFICATION"),
        ),
        Spacer(),
      ],
    );
  }

  grtOTPFormWidget(BuildContext context) {
    return Column(
      children: [
        Spacer(),
        TextField(
          controller: otpController,
          decoration: InputDecoration(
              hintText: "Enter OTP"
          ),
        ),
        SizedBox(height: 16,),
        ElevatedButton(
          onPressed: () async{
            PhoneAuthCredential phoneAuthCredential =
            PhoneAuthProvider.credential(
                verificationId: verificationId,
                smsCode: otpController.text
            );
            signInWithAuthCredential(phoneAuthCredential);
          },
          child: Text("VERIFY"),
        ),
        Spacer(),
      ],
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Login Screen"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          child: showLoading ? Center(child: CircularProgressIndicator(),) :
          currentState == MobileVerificationState.SHOW_MOBILE_FORM_STATE ?
          getMobileFormWidget(context) :
          grtOTPFormWidget(context),
        ),
      )
    );
  }
}


