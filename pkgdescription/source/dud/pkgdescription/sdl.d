module dud.pkgdescription.sdl;

import std.conv : to;
import std.exception : enforce;
import std.format : format;

import dud.pkgdescription : Dependency, PackageDescription, TargetType;
import dud.semver : SemVer;
import dud.path : Path;

import dud.sdlang;

PackageDescription sdlToPackageDescription(string sdl) {
	Tag jv = parseSource(sdl);
	return sdlToPackageDescription(jv);
}

PackageDescription sdlToPackageDescription(Tag t) {
	import dud.pkgdescription.helper : PreprocessKey, KeysToSDLCases;

	import std.stdio;

	writeln("Attributes");
	foreach(it; t.attributes()) {
		writeln(it);
	}

	writeln("Tags");
	foreach(Tag it; t.tags()) {
		writefln("%s %s", it.name, it.values);
		try {
			sw: switch(it.name) {
				static foreach(mem; __traits(allMembers, PackageDescription)) {{
					enum Mem = KeysToSDLCases!(PreprocessKey!(mem));
					case Mem: {
						static if(is(MemType == string)) {
							__traits(getMember, ret, mem) =
									extractString(it.values);
						} else static if(is(MemType == string[])) {
							__traits(getMember, ret, mem) =
									extractString(it.values);
						} else static if(is(MemType == TargetType)) {
							__traits(getMember, ret, mem) =
									extractTargetType(it.values);
						}
						break sw;
					}
				}}
				default:
					enforce(false, format("key '%s' unknown", it.name));
					assert(false);
			}
		} catch(Exception e) {
			string s = format("While parsing key '%s' an exception occured",
					it.name);
			throw new Exception(s, e);
		}

	}
	return PackageDescription.init;
}

string[] extractStrings(Value v) {
	enforce(v.type == typeid(string[]), format("Expected a string[] not a '%s'",
				v.type.stringof));
	return v.get!(string[])();
}

string extractString(Value v) {
	enforce(v.type == typeid(string), format("Expected a string not a '%s'",
				v.type.stringof));
	return v.get!string();
}

TargetType extractTargetType(Value v) {
	return to!TargetType(extractString(v));
}
