import 'dart:typed_data';
import 'dart:html';
import 'dart:math';
import 'dart:web_audio';

// Run timers at 60 Hz (16 milliseconds per tick).
const int TICKS_PER_HZ = 16;

// Sprites for hex digits 0 - F.
const List<int> HEX_DIGITS = [
  0xF0, 0x90, 0x90, 0x90, 0xF0,
  0x20, 0x60, 0x20, 0x20, 0x70,
  0xF0, 0x10, 0xF0, 0x80, 0xF0,
  0xF0, 0x10, 0xF0, 0x10, 0xF0,
  0x90, 0x90, 0xF0, 0x10, 0x10,
  0xF0, 0x80, 0xF0, 0x10, 0xF0,
  0xF0, 0x80, 0xF0, 0x90, 0xF0,
  0xF0, 0x10, 0x20, 0x40, 0x40,
  0xF0, 0x90, 0xF0, 0x90, 0xF0,
  0xF0, 0x90, 0xF0, 0x10, 0xF0,
  0xF0, 0x90, 0xF0, 0x90, 0x90,
  0xE0, 0x90, 0xE0, 0x90, 0xE0,
  0xF0, 0x80, 0x80, 0x80, 0xF0,
  0xE0, 0x90, 0x90, 0x90, 0xE0,
  0xF0, 0x80, 0xF0, 0x80, 0xF0,
  0xF0, 0x80, 0xF0, 0x80, 0x80,
];

class Display {
  Display(CanvasElement canvas) {
    _canvas = canvas;
    _ctx = canvas.getContext('2d');

    // Init _screen to be empty.
    _screen = new List<List<bool>>(32);
    for (int i = 0; i < 32; i++) {
      _screen[i] = new List<bool>.filled(64, false);
    }

  }

  void Clear() {
    _ctx.clearRect(0, 0, _canvas.width, _canvas.height);

    for (int i = 0; i < 32; i++) {
      for(int j = 0; j < 64; j++) {
        _screen[i][j] = false;
      }
    }

  }

  bool Draw(Uint8List data, int x, int y, int height) {
    bool collision = false;
    for (int i = 0; i < height; i++) {
      // print(data[i].toRadixString(2).padLeft(8, '0'));
      for (int j = 0; j < 8; j++) {
        if (data[i] & (0x1 << j) > 0) {
          if (DrawPixel(x + (8 - j), y + i)) {
            collision = true;
          }
        }
      }
    }

    return collision;
  }

  // Draw a single "pixel" on screen.
  bool DrawPixel(int x, int y) {
    //  Wrap around.
    x = x % 64;
    y = y % 32;

    // If this pixel is already drawn on screen, remove it and return a collision.
    if (_screen[y][x]) {
      _screen[y][x] = false;
      _ctx.setFillColorRgb(255, 255, 255); // White
      _ctx.fillRect(x * 10, y * 10, 10, 10);
      return true;
    }

    _screen[y][x] = true;
    _ctx.setFillColorRgb(0, 0, 0); // Black
    _ctx.fillRect(x * 10, y * 10, 10, 10);
    return false;
  }

  CanvasElement _canvas;
  CanvasRenderingContext2D _ctx;

  // Keep track of what is shown on screen for XOR'ing sprites onto the screen.
  List<List<bool>> _screen;
}

// Helper class to track which keys are pressed.
class Keyboard {
  Keyboard() {
    _keys = new Map<int, num>();

    window.onKeyDown.listen((KeyboardEvent e) {
      _keys.putIfAbsent(e.keyCode, () => e.timeStamp);
    });

    window.onKeyUp.listen((KeyboardEvent e) {
      _keys.remove(e.keyCode);
    });
  }

  bool isPressed(int value) {
    return _keys.containsKey(GetKeyCode(value));
  }

  // Returns -1 if no key is pressed.
  int isAnyPressed() {
    if (_keys.length > 0) {
      return GetValue(_keys.keys.first);
    }

    return -1;
  }

  // Map hex value to key.
  int GetKeyCode(int value) {
    switch (value) {
      case 1:
        return KeyCode.ONE;
      case 2:
        return KeyCode.TWO;
      case 3:
        return KeyCode.THREE;
      case 4:
        return KeyCode.Q;
      case 5:
        return KeyCode.W;
      case 6:
        return KeyCode.E;
      case 7:
        return KeyCode.A;
      case 8:
        return KeyCode.S;
      case 9:
        return KeyCode.D;
      case 0:
        return KeyCode.X;
      case 0xA:
        return KeyCode.Z;
      case 0xB:
        return KeyCode.C;
      case 0xC:
        return KeyCode.FOUR;
      case 0xD:
        return KeyCode.R;
      case 0xE:
        return KeyCode.F;
      case 0xF:
        return KeyCode.V;
    }

    return 0;
  }

  // Map key to hex value.
  int GetValue(int key) {
    switch (key) {
      case KeyCode.ONE:
        return 1;
      case KeyCode.TWO:
        return 2;
      case KeyCode.THREE:
        return 3;
      case KeyCode.Q:
        return 4;
      case KeyCode.W:
        return 5;
      case KeyCode.E:
        return 6;
      case KeyCode.A:
        return 7;
      case KeyCode.S:
        return 8;
      case KeyCode.D:
        return 9;
      case KeyCode.X:
        return 0;
      case KeyCode.Z:
        return 0xA;
      case KeyCode.C:
        return 0xB;
      case KeyCode.FOUR:
        return 0xC;
      case KeyCode.R:
        return 0xD;
      case KeyCode.F:
        return 0xE;
      case KeyCode.V:
        return 0xF;
    }
    return -1;
  }

  Map<int, num> _keys;

}

// Helper class for playing a tone.
class Audio {
  Audio() {
    _context = new AudioContext();
  }

  void Start() {
    _node = _context.createOscillator();
    _node.connectNode(_context.destination);
    _node.start2(0);
  }

  void Stop() {
    _node.disconnect();
    _node = null;
  }

  AudioContext _context;
  OscillatorNode _node;
}

class Chip8 {
  Chip8(CanvasElement canvas) {
    _ram = new Uint8List(0x1000);
    _reg = new Uint8List(16);

    _pc = 0x200; // Default starting address.
    _sp = 0;
    _stack = new Uint16List(16);

    _display = new Display(canvas);
    _keyboard = new Keyboard();
    _audio = new Audio();

    _rand = new Random();

    // Copy hex digits into memory.
    for (int i = 0; i < HEX_DIGITS.length; i++) {
      _ram[i] = HEX_DIGITS[i];
    }
  }

  // Copy rom into ram starting at 0x200.
  void LoadRom(Uint8List rom) {
    print(rom);
    for (int i = 0; i < rom.length; i++) {
      _ram[0x200 + i] = rom[i];
    }
  }

  // time is the number of milliseconds that have elapsed since the last step.
  void Step(num time) {
    // Decrement pending timers.
    _pendingTicks += time;
    if (_pendingTicks > TICKS_PER_HZ) {
      if (_st > 0) _st--;
      if (_dt > 0) _dt--;
      _pendingTicks -= TICKS_PER_HZ;
    }

    // Check if audio should be started or stopped.
    if (_st > 0 && !playing) {
      _audio.Start();
      playing = true;
    } else if (_st == 0 && playing) {
      _audio.Stop();
      playing = false;
    }

    // Handle waits on keyboard input.
    if (keyWait) {
      int key = _keyboard.isAnyPressed();
      if (key >= 0) {
        keyWait = false;
        _reg[keyReg] = key;
      }
      return;
    }

    int op = (_ram[_pc] << 8) + _ram[_pc+1];
    _pc += 2;

    // print(op.toRadixString(16).padLeft(4, '0'));

    // Giant switch to handle all op codes.
    switch ((op & 0xF000) >> 12) {
      case 0x0: // 0nnn - SYS addr
        // Check for specific system functions that are supported.
        switch(op) {
          case 0x00E0: // CLS
            _display.Clear();
            break;
          case 0x00EE: // RET
            _pc = _stack[--_sp];
            break;
        }
        break;
      case 0x1: // 1nnn - JP addr
        _pc = op & 0xFFF;
        break;
      case 0x2: // 2nnn - CALL addr
        _stack[_sp++] = _pc;
        _pc = op & 0xFFF;
        break;
      case 0x3: // 3xkk - SE Vx, byte
        if (_reg[(op & 0xF00) >> 8] == (op & 0xFF)) {
          _pc += 2;
        }
        break;
      case 0x4: // 4xkk - SNE Vx, byte
        if (_reg[(op & 0xF00) >> 8] != (op & 0xFF)) {
          _pc += 2;
        }
        break;
      case 0x5: // 5xy0 - SE Vx, Vy
        if (_reg[(op & 0xF00) >> 8] == _reg[(op & 0xF0) >> 4]) {
          _pc += 2;
        }
        break;
      case 0x6: // 6xkk - LD Vx, byte
        _reg[(op & 0xF00) >> 8] = op & 0xFF;
        break;
      case 0x7: // 7xkk - ADD Vx, byte
        _reg[(op & 0xF00) >> 8] += op & 0xFF;
        break;
      case 0x8: // Various register operations
        int x = (op & 0xF00) >> 8;
        int y = (op & 0xF0) >> 4;

        switch (op & 0xF) {
          case 0: // 8xy0 - LD Vx, Vy
            _reg[x] = _reg[y];
            break;
          case 1: // 8xy1 - OR Vx, Vy
            _reg[x] = _reg[x] | _reg[y];
            break;
          case 2: // 8xy2 - AND Vx, Vy
            _reg[x] = _reg[x] & _reg[y];
            break;
          case 3: // 8xy3 - XOR Vx, Vy
            _reg[x] = _reg[x] ^ _reg[y];
            break;
          case 4: // 8xy4 - ADD Vx, Vy
            _reg[x] = _reg[x] + _reg[y];
            _reg[0xF] = (_reg[x] > 0xFFFF ? 1 : 0);
            _reg[x] = _reg[x] & 0xFFF;
            break;
          case 5: // 8xy5 - SUB Vx, Vy
            _reg[0xF] = (_reg[x] > _reg[y] ? 1 : 0);
            _reg[x] = (_reg[x] + 0x1000 - _reg[y]) & 0xFFF;
            break;
          case 6: // 8xy6 - SHR Vx {, Vy}
            _reg[0xF] = _reg[x] & 0x1;
            _reg[x] = _reg[x] >> 1;
            break;
          case 7: // 8xy7 - SUBN Vx, Vy
            _reg[0xF] = (_reg[y] > _reg[x] ? 1 : 0);
            _reg[x] = (_reg[y] + 0x1000 - _reg[x]) & 0xFFF;
            break;
          case 0xE: // 8xyE - SHL Vx {, Vy}
            _reg[0xF] = ((_reg[x] & 0x800) > 0 ? 1 : 0);
            _reg[x] = (_reg[x] << 1) & 0xFFF;
            break;

        }
        break;
      case 0x9: // 5xy0 - SNE Vx, Vy
        if (_reg[(op & 0xF00) >> 8] != _reg[(op & 0xF0) >> 4]) {
          _pc += 2;
        }
        break;
      case 0xA: // Annn - LD I, addr
        _i = op & 0xFFF;
        break;
      case 0xB: // Bnnn - JP V0, addr
        _pc = (op & 0xFFF) + _reg[0];
        break;
      case 0xC: // RND Vx, byte
        int x = (op & 0xF00) >> 8;
        _reg[x] = _rand.nextInt(256) & (op & 0xFF);
        break;
      case 0xD: // DRW Vx, Vy, nibble
        int x = _reg[(op & 0xF00) >> 8];
        int y = _reg[(op & 0xF0) >> 4];
        int height = op & 0xF;

        Uint8List bytes = new Uint8List(height);
        for (int i = 0; i < height; i++) {
          bytes[i] = _ram[_i + i];
        }

        bool col = _display.Draw(bytes, x, y, height);
        _reg[0xF] = (col ? 1 : 0);

        break;
      case 0xE: // Keyboard operations
        int x = _reg[(op & 0xF00) >> 8];
        switch (op & 0xFF) {
          case 0x9E: // Ex9E - SKP Vx
            if (_keyboard.isPressed(x)) {
              _pc += 2;
            }
            break;
          case 0xA1: // ExA1 - SKNP Vx
            if (!_keyboard.isPressed(x)) {
              _pc += 2;
            }
            break;
        }
        break;
      case 0xF: // Various operations
        int x = (op & 0xF00) >> 8;

        switch (op & 0xFF) {
          case 0x07: // Fx07 - LD Vx, DT
            _reg[x] = _dt;
            break;
          case 0x0A: // Fx0A - LD Vx, K
            keyWait = true;
            keyReg = x;
            break;
          case 0x15: // Fx15 - LD DT, Vx
            _dt = _reg[x];
            break;
          case 0x18: // Fx18 - LD ST, Vx
            _st = _reg[x];
            break;
          case 0x1E: // Fx1E - ADD I, Vx
            _i += _reg[x];
            break;
          case 0x29: // Fx29 - LD F, Vx
            _i = _reg[x] * 5;
            break;
          case 0x33: // Fx33 - LD B, Vx
            int val = _reg[x];
            _ram[_i] = val ~/ 100;
            _ram[_i + 1] = (val ~/ 10) % 10;
            _ram[_i + 2] = val % 10;
            break;
          case 0x55: // Fx55 - LD [I], Vx
            for (int i = 0; i <= x; i++) {
              _ram[_i + i] = _reg[i];
            }
            break;
          case 0x65: // Fx65 - LD Vx, [I]
            for (int i = 0; i <= x; i++) {
              _reg[i] = _ram[_i + i];
            }
            break;
        }
        break;
      default:
        print("Op not implemented: " + op.toRadixString(16).padLeft(4, '0'));
    }

    // print(_reg);
    // print("PC: $_pc I: $_i SP: $_sp");
  }

  // Registers and RAM.
  Uint8List _ram;
  int _pc;
  Uint8List _reg; // V0 - VF
  int _i;

  // Store stack outside of RAM for ease of use. Could put this in the system
  // section of RAM to be more realistic.
  int _sp;
  Uint16List _stack;

  // Timers.
  int _pendingTicks = 0;
  int _dt = 0;
  int _st = 0;

  Display _display;
  Keyboard _keyboard;

  Audio _audio;
  bool playing = false; // Whether audio is currently playing.

  bool keyWait = false; // Whether we are waiting on a key press.
  int keyReg; // The register to store the key press.

  Random _rand;
}