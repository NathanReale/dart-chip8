import 'dart:html';
import 'dart:typed_data';

import 'chip-8.dart';

const num STEP_SIZE = 2;

class Game {
  Game() {
    CanvasElement canvas = querySelector("#canvas");
    ch8 = new Chip8(canvas);
  }

  void Start() {
    _stop = false;
    Run();
  }

  Future Run() async {
    Update(await window.animationFrame);
  }

  void Update(num timestamp) {
    if (_lastTimestamp == null) {
      _lastTimestamp = timestamp;
    } else {
      num delta = timestamp - _lastTimestamp;
      _lastTimestamp = timestamp;
      while (delta > STEP_SIZE) {
        ch8.Step(STEP_SIZE);
        delta -= STEP_SIZE;
      }
    }

    if (!_stop) Run();
  }

  void Step() {
    ch8.Step(STEP_SIZE);
  }

  void LoadRom(Uint8List rom) {
    ch8.LoadRom(rom);
  }

  void Stop() {
    _stop = true;
  }

  Chip8 ch8;
  bool _stop = false;

  num _lastTimestamp;
}


void main() {
  Game g = new Game();

  // Load a ROM
  ButtonElement load = querySelector("#load");
  load.onClick.listen((Event e) async {
    FileUploadInputElement fileInput = new FileUploadInputElement();
    fileInput.style.display = 'none';
    fileInput.accept = ".ch8";
    document.body.children.add(fileInput);
    fileInput.click();

    await fileInput.onChange.first;
    FileReader reader = new FileReader();
    reader.readAsArrayBuffer(fileInput.files.first);
    await reader.onLoadEnd.first;

    g.LoadRom(reader.result);
  });

  ButtonElement step = querySelector("#step");
  step.onClick.listen((Event e) {
    g.Step();
  });

  ButtonElement execute = querySelector("#execute");
  execute.onClick.listen((Event e) {
    g.Start();
  });

  ButtonElement stop = querySelector("#stop");
  stop.onClick.listen((Event e) {
    g.Stop();
  });

}
