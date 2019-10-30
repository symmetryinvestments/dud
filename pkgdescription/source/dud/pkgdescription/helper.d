module dud.pkgdescription.helper;

template PreprocessKey(string key) {
	import std.algorithm.searching : endsWith;
	static if(key.endsWith("_")) {
		enum PreprocessKey = key[0 .. $ - 1];
	} else {
		enum PreprocessKey = key;
	}
}
