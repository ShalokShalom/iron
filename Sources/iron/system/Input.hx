package iron.system;

class Input {

	public static var occupied = false;
	static var mouse:Mouse = null;
	static var keyboard:Keyboard = null;
	static var gamepads:Array<Gamepad> = [];
	static var sensor:Sensor = null;
	static var virtualButtons:Map<String, VirtualButton> = null; // Button name

	public static function reset() {
		occupied = false;
		if (mouse != null) mouse.reset();
		if (keyboard != null) keyboard.reset();
		for (gamepad in gamepads) gamepad.reset();
	}

	public static function endFrame() {
		if (mouse != null) mouse.endFrame();
		if (keyboard != null) keyboard.endFrame();
		for (gamepad in gamepads) gamepad.endFrame();

		if (virtualButtons != null) {
			for (vb in virtualButtons) vb.started = vb.released = false;
		}
	}

	public static function getMouse():Mouse {
		if (mouse == null) mouse = new Mouse();
		return mouse;
	}

	public static function getSurface():Surface {
		// Map to mouse for now..
		return getMouse();
	}

	public static function getKeyboard():Keyboard {
		if (keyboard == null) keyboard = new Keyboard();
		return keyboard;
	}

	public static function getGamepad(i:Int = 0):Gamepad {
		if (i >= 4) return null;
		while (gamepads.length <= i) gamepads.push(new Gamepad(gamepads.length));
		return gamepads[i];
	}

	public static function getSensor():Sensor {
		if (sensor == null) sensor = new Sensor();
		return sensor;
	}

	public static function startedVirtual(virtual:String):Bool {
		if (virtualButtons == null) return false;
		var button = virtualButtons.get(virtual);
		return button != null ? button.started : false;
	}

	public static function releasedVirtual(virtual:String):Bool {
		if (virtualButtons == null) return false;
		var button = virtualButtons.get(virtual);
		return button != null ? button.released : false;
	}

	public static function downVirtual(virtual:String):Bool {
		if (virtualButtons == null) return false;
		var button = virtualButtons.get(virtual);
		return button != null ? button.down : false;
	}

	public static function getVirtualButton(virtual:String):VirtualButton {
		if (virtualButtons == null) virtualButtons = new Map<String, VirtualButton>();
		var button = virtualButtons.get(virtual);
		if (button == null) {
			button = new VirtualButton();
			virtualButtons.set(virtual, button);
		}
		return button;
	}
}

class VirtualButton {
	public var started = false;
	public var released = false;
	public var down = false;
	public function new() {}
}

class VirutalInput {
	var virtualButtons:Map<String, VirtualButton> = null; // Button id

	public function setVirtual(virtual:String, button:String) {
		var vb = Input.getVirtualButton(virtual);
		if (virtualButtons == null) virtualButtons = new Map<String, VirtualButton>();
		virtualButtons.set(button, vb);
	}

	function downVirtual(button:String) {
		if (virtualButtons != null) {
			var vb = virtualButtons.get(button);
			if (vb != null) { vb.down = true; vb.started = true; }
		}
	}

	function upVirtual(button:String) {
		if (virtualButtons != null) {
			var vb = virtualButtons.get(button);
			if (vb != null) { vb.down = false; vb.released = true; }
		}
	}
}

typedef Surface = Mouse;

class Mouse extends VirutalInput {

	static var buttons = ['left', 'right', 'middle'];
	var buttonsDown = [false, false, false];
	var buttonsStarted = [false, false, false];
	var buttonsReleased = [false, false, false];

	public var x(default, null) = 0.0;
	public var y(default, null) = 0.0;
	public var moved(default, null) = false;
	public var movementX(default, null) = 0.0;
	public var movementY(default, null) = 0.0;
	public var wheelDelta(default, null) = 0;
	// var lastX = 0.0;
	// var lastY = 0.0;

	public function new() {
		kha.input.Mouse.get().notify(downListener, upListener, moveListener, wheelListener);
	}

	public function endFrame() {
		buttonsStarted[0] = buttonsStarted[1] = buttonsStarted[2] = false;
		buttonsReleased[0] = buttonsReleased[1] = buttonsReleased[2] = false;
		moved = false;
		movementX = 0;
		movementY = 0;
		wheelDelta = 0;
	}

	public function reset() {
		buttonsDown[0] = buttonsDown[1] = buttonsDown[2] = false;
		endFrame();
	}

	function buttonIndex(button:String) {
		return button == "left" ? 0 : (button == "right" ? 1 : 2);
	}

	public function down(button:String = "left"):Bool {
		return buttonsDown[buttonIndex(button)];
	}

	public function started(button:String = "left"):Bool {
		return buttonsStarted[buttonIndex(button)];
	}

	public function released(button:String = "left"):Bool {
		return buttonsReleased[buttonIndex(button)];
	}
	
	function downListener(index:Int, x:Float, y:Float) {
		buttonsDown[index] = true;
		buttonsStarted[index] = true;
		this.x = x;
		this.y = y;

		downVirtual(buttons[index]);
	}
	
	function upListener(index:Int, x:Float, y:Float) {
		buttonsDown[index] = false;
		buttonsReleased[index] = true;
		this.x = x;
		this.y = y;

		upVirtual(buttons[index]);
	}
	
	function moveListener(x:Int, y:Int, movementX:Int, movementY:Int) {
		this.movementX = movementX;
		this.movementY = movementY;
		// movementX = x - lastX;
		// movementY = y - lastY;
		// lastX = x;
		// lastY = y;
		this.x = x;
		this.y = y;
		moved = true;
	}

	function wheelListener(delta:Int) {
		wheelDelta = delta;
	}
}

class Keyboard extends VirutalInput {

	static var keys = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', ',', 'space', 'backspace', 'tab', 'enter', 'shift', 'ctrl', 'alt', 'esc', 'del', 'back', 'up', 'right', 'left', 'down'];
	var keysDown = new Map<String, Bool>();
	var keysStarted = new Map<String, Bool>();
	var keysReleased = new Map<String, Bool>();

	var keysFrame:Array<String> = [];

	public function new() {
		reset();
		kha.input.Keyboard.get().notify(downListener, upListener);
	}

	public function endFrame() {
		if (keysFrame.length > 0) {
			for (s in keysFrame) {
				keysStarted.set(s, false);
				keysReleased.set(s, false);
			}
			keysFrame.splice(0, keysFrame.length);
		}
	}

	public function reset() {
		// Use Map for now..
		for (s in keys) {
			keysDown.set(s, false);
			keysStarted.set(s, false);
			keysReleased.set(s, false);
		}
		endFrame();
	}

	public function down(key:String):Bool {
		return keysDown.get(key);
	}

	public function started(key:String):Bool {
		return keysStarted.get(key);
	}

	public function released(key:String):Bool {
		return keysReleased.get(key);
	}

	function keyToString(key: kha.Key, char: String) {
		if (key == kha.Key.CHAR) return char == " " ? "space" : char.toLowerCase();
		else if (key == kha.Key.BACKSPACE) return "backspace";
		else if (key == kha.Key.TAB) return "tab";
		else if (key == kha.Key.ENTER) return "enter";
		else if (key == kha.Key.SHIFT) return "shift";
		else if (key == kha.Key.CTRL) return "ctrl";
		else if (key == kha.Key.ALT) return "alt";
		else if (key == kha.Key.ESC) return "esc";
		else if (key == kha.Key.DEL) return "del";
		else if (key == kha.Key.UP) return "up";
		else if (key == kha.Key.DOWN) return "down";
		else if (key == kha.Key.LEFT) return "left";
		else if (key == kha.Key.RIGHT) return "right";
		else if (key == kha.Key.BACK) return "back";
		return "";
	}

	function downListener(key: kha.Key, char: String) {
		var s = keyToString(key, char);
		keysFrame.push(s);
		keysStarted.set(s, true);
		keysDown.set(s, true);

		downVirtual(s);
	}

	function upListener(key: kha.Key, char: String) {
		var s = keyToString(key, char);
		keysFrame.push(s);
		keysReleased.set(s, true);
		keysDown.set(s, false);

		upVirtual(s);
	}
}

class GamepadStick {
	public var x = 0.0;
	public var y = 0.0;
	public var lastX = 0.0;
	public var lastY = 0.0;
	public var moved = false;
	public var movementX = 0.0;
	public var movementY = 0.0;
	public function new() {}
}

class Gamepad extends VirutalInput {

	static var buttonsPS = ['cross', 'circle', 'square', 'triangle', 'l1', 'r1', 'l2', 'r2', 'share', 'options', 'l3', 'r3', 'up', 'down', 'left', 'right', 'home', 'touchpad'];
	// static var buttonsXBOX = ['a', 'b', 'x', 'y', 'l1', 'r1', 'l2', 'r2', 'share', 'options', 'l3', 'r3', 'up', 'down', 'left', 'right', 'home', 'touchpad'];

	var buttonsDown:Array<Float> = []; // Intensity 0 - 1
	var buttonsStarted:Array<Bool> = [];
	var buttonsReleased:Array<Bool> = [];

	var buttonsFrame:Array<Int> = [];

	public var leftStick = new GamepadStick();
	public var rightStick = new GamepadStick();

	var num = 0;

	public function new(i:Int) {
		for (s in buttonsPS) {
			buttonsDown.push(0.0);
			buttonsStarted.push(false);
			buttonsReleased.push(false);
		}
		num = i;
		reset();
		connect();
	}

	var connects = 0;
	function connect() {
		var gamepad = kha.input.Gamepad.get(num);
		if (gamepad == null) {
			if (connects < 10) armory.system.Tween.timer(1, connect);
			connects++;
			return;
		}
		gamepad.notify(axisListener, buttonListener);
	}

	public function endFrame() {
		if (buttonsFrame.length > 0) {
			for (i in buttonsFrame) {
				buttonsStarted[i] = false;
				buttonsReleased[i] = false;
			}
			buttonsFrame.splice(0, buttonsFrame.length);
		}
		leftStick.moved = false;
		leftStick.movementX = 0;
		leftStick.movementY = 0;
		rightStick.moved = false;
		rightStick.movementX = 0;
		rightStick.movementY = 0;
	}

	public function reset() {
		for (i in 0...buttonsDown.length) {
			buttonsDown[i] = 0.0;
			buttonsStarted[i] = false;
			buttonsReleased[i] = false;
		}
		endFrame();
	}

	function buttonIndex(button:String):Int {
		for (i in 0...buttonsPS.length) if (buttonsPS[i] == button) return i;
		return 0;
	}

	public function down(button:String):Float {
		return buttonsDown[buttonIndex(button)];
	}

	public function started(button:String):Bool {
		return buttonsStarted[buttonIndex(button)];
	}

	public function released(button:String):Bool {
		return buttonsReleased[buttonIndex(button)];
	}

	function axisListener(axis:Int, value:Float) {
		var stick = axis <= 1 ? leftStick : rightStick;

		if (axis == 0 || axis == 2) { // X
			stick.x = value;
			stick.movementX = stick.x - stick.lastX;
			stick.lastX = stick.x;
		}
		else if (axis == 1 || axis == 3) { // Y
			stick.y = value;
			stick.movementY = stick.y - stick.lastY;
			stick.lastY = stick.y;
		}
		stick.moved = true;
	}

	function buttonListener(button:Int, value:Float) {
		buttonsFrame.push(button);

		buttonsDown[button] = value;
		if (value > 0) buttonsStarted[button] = true; // Will trigger L2/R2 multiple times..
		else buttonsReleased[button] = true;

		if (value == 0.0) upVirtual(buttonsPS[button]);
		else if (value == 1.0) downVirtual(buttonsPS[button]);
	}
}

class Sensor {

	public var x = 0.0;
	public var y = 0.0;
	public var z = 0.0;

	public function new() {
		kha.input.Sensor.get(kha.input.SensorType.Accelerometer).notify(listener);
	}

	function listener(x:Float, y:Float, z:Float) {
		this.x = x;
		this.y = y;
		this.z = z;
	}
}
