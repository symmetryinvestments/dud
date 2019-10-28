module dud.pkgdescription.helper;

template PreprocessKey(string key) {
	import std.algorithm.searching : endsWith;
	static if(key.endsWith("_")) {
		enum PreprocessKey = key[0 .. $ - 1];
	} else {
		enum PreprocessKey = key;
	}
}

template KeysToSDLCases(string key) {
	static if(key == "dependencies") {
		enum KeysToSDLCases = "dependency";
	} else static if(key == "configurations") {
		enum KeysToSDLCases = "configuration";
	} else {
		enum KeysToSDLCases = key;
	}
}
