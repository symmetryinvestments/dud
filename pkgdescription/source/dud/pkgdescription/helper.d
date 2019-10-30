module dud.pkgdescription.helper;

template PreprocessKey(string key) {
	import std.algorithm.searching : endsWith;
	static if(key.endsWith("_")) {
		enum PreprocessKey = key[0 .. $ - 1];
	} else {
		enum PreprocessKey = key;
	}
}

__EOF__

template KeysToSDLCases(string key) {
	static if(key == "dependencies") {
		enum KeysToSDLCases = "dependency";
	} else static if(key == "configurations") {
		enum KeysToSDLCases = "configuration";
	} else {
		enum KeysToSDLCases = SDLUdaName!key;
	}
}

template SDLUdaName(string key) {
	import dud.pkgdescription.udas;
	import dud.pkgdescription : PackageDescription;

	static if(__traits(hasMember, PackageDescription, key)) {
		enum attr = __traits(getAttributes,
				__traits(getMember, PackageDescription, key));

		static if(attr.length == 1) {
			alias First = attr[0];
			alias FirstType = typeof(First);
			static if(is(FirstType == SDLName)) {
				enum SDLUdaName = attr[0].name;
			} else {
				enum SDLUdaName = key;
			}
		} else {
			enum SDLUdaName = key;
		}
	} else {
		enum SDLUdaName = key;
	}
}
