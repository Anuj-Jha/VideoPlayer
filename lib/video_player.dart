import 'dart:async';

import 'package:camera/camera.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:volume_control/volume_control.dart';

class VideoPlayerScreen extends StatefulWidget {
  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController _videoPlayerController1;
  ChewieController _chewieController;
  double _val = 0.5;
  Timer timer;
  CameraController cameraController;
  List cameras;
  int selectedCameraIndex;
  double _cameraViewRightPosition = 20.0;
  double _cameraViewBottomPosition = 20.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    initVolumeState();
    initializePlayer();
    _setCamera();
  }

  _setCamera() {
    availableCameras().then((value) {
      cameras = value;
      if(cameras.length > 0){
        setState(() {
          selectedCameraIndex = 1;
        });
        initCamera(cameras[selectedCameraIndex]).then((value) {

        });
      } else {
        print('No camera available');
      }
    }).catchError((e){
      print('Error : ${e.code}');
    });
  }

  //init volume_control plugin
  Future<void> initVolumeState() async {
    if (!mounted) return;

    //read the current volume
    _val = await VolumeControl.volume;
    setState(() {
    });
  }

  Future<void> initializePlayer() async {
    _videoPlayerController1 = VideoPlayerController.network(
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4');
    await Future.wait([
      _videoPlayerController1.initialize(),
    ]);
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController1,
      autoPlay: true,
      looping: true,
      showControls: false,
    );
    setState(() {});
  }

  Future initCamera(CameraDescription cameraDescription) async {
    if (cameraController != null) {
      await cameraController.dispose();
    }

    cameraController =
        CameraController(cameraDescription, ResolutionPreset.high);

    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    if (cameraController.value.hasError) {
      print('Camera Error ${cameraController.value.errorDescription}');
    }

    try {
      await cameraController.initialize();
    } catch (e) {
      String errorText = 'Error ${e.code} \nError message: ${e.description}';
    }

    if (mounted) {
      setState(() {});
    }
  }

  Widget cameraPreview() {
    if (cameraController == null || !cameraController.value.isInitialized) {
      return Text(
        'Loading',
        style: TextStyle(
            color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
      );
    }

    return AspectRatio(
      aspectRatio: cameraController.value.aspectRatio,
      child: CameraPreview(cameraController),
    );
  }

  @override
  void dispose() {
    _videoPlayerController1.dispose();
    _chewieController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _body(),
    );
  }

  _body() {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: Colors.black,
      child: Column(
        children: <Widget>[
          Stack(
            //alignment: Alignment.center,
            children: [
              Expanded(
                child: Center(
                  child: _chewieController != null &&
                          _chewieController
                              .videoPlayerController.value.initialized
                      ? Chewie(
                          controller: _chewieController,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(),
                            SizedBox(height: 20),
                            Text('Loading'),
                          ],
                        ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 50,
                child: Row(
                  children: [
                    Icon(Icons.audiotrack_outlined),
                    Slider(value:_val,min:0,max:1,divisions: 100,onChanged:(val){
                      _val = val;
                      setState(() {});
                      if (timer!=null){
                        timer.cancel();
                      }
                      timer = Timer(Duration(milliseconds: 200), (){VolumeControl.setVolume(val);});
                    }),
                  ],
                ),
              ),

              Positioned(
                bottom: _cameraViewBottomPosition,
                right: _cameraViewRightPosition,
                child: Draggable(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Container(
                      width: 150,
                      height: 120,
                      child: cameraPreview(),
                    ),
                  ),
                  feedback: RotatedBox(
                    quarterTurns: 3,
                    child: Container(
                      width: 150,
                      height: 120,
                      child: cameraPreview(),
                    ),
                  ),
                  childWhenDragging: Container(),
                  onDragEnd: (dragDetails) {
                    setState(() {
                      _cameraViewRightPosition = (MediaQuery.of(context).size.width - dragDetails.offset.dx) - 120.0;
                      _cameraViewBottomPosition = (MediaQuery.of(context).size.height - dragDetails.offset.dy) - 150.0;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
