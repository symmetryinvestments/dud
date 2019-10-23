module dud.pkgdescription.sdl;

import std.array : array, front;
import std.algorithm.iteration : map;
import std.conv : to;
import std.exception : enforce;
import std.format : format;
import std.typecons : nullable;
import std.stdio;

import dud.pkgdescription : Dependency, PackageDescription, TargetType;
import dud.semver : SemVer;
import dud.path : Path;

import dud.sdlang;

PackageDescription sdlToPackageDescription(string sdl) @trusted {
	Tag jv = parseSource(sdl);
	return sdlToPackageDescription(jv);
}

PackageDescription sdlToPackageDescription(Tag t) {
	import dud.pkgdescription.helper : PreprocessKey, KeysToSDLCases;

	import std.stdio;

	PackageDescription ret;

	foreach(it; t.attributes()) {
		writeln(it);
	}

	foreach(Tag it; t.tags()) {
		writefln("%s %s", it.name, it.values);
		try {
			sw: switch(it.name) {
				static foreach(mem; __traits(allMembers, PackageDescription)) {{
					enum Mem = KeysToSDLCases!(PreprocessKey!(mem));
					case Mem: {
						alias MemType = typeof(__traits(getMember, PackageDescription, mem));
						static if(is(MemType == string)) {
							__traits(getMember, ret, mem) =
									extractString(it.values);
						} else static if(is(MemType == SemVer)) {
							__traits(getMember, ret, mem) =
								extractSemVer(it.values);
						} else static if(is(MemType == Path)) {
							__traits(getMember, ret, mem) =
								extractPath(it.values);
						} else static if(is(MemType == Path[])) {
							__traits(getMember, ret, mem) =
								extractPaths(it.values);
						} else static if(is(MemType == string[])) {
							__traits(getMember, ret, mem) =
									extractStrings(it.values);
						} else static if(is(MemType == TargetType)) {
							__traits(getMember, ret, mem) =
									extractTargetType(it.values);
						} else static if(is(MemType == Dependency[string])) {
							string name = extractString(it.values);
							enforce(name !in __traits(getMember, ret, mem),
								format("Dependency '%s' already exist", name));
							__traits(getMember, ret, mem)[name] =
									extractDependency(it);
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
	return ret;
}

string[] extractStrings(Value[] v) {
	return v.map!(it => extractString(it)).array;
}

string extractString(Value[] v) {
	enforce(v.length == 1, format("Expected a length of 1 not '%u'", v.length));
	return extractString(v.front);
}

string extractString(Value v) {
	enforce(v.type == typeid(string), format("Expected a string not a '%s'",
				v.type.stringof));
	return v.get!string();
}

bool extractBool(Value[] v) {
	enforce(v.length == 1, format("Expected a length of 1 not '%u'", v.length));
	return extractBool(v.front);
}

bool extractBool(Value v) {
	enforce(v.type == typeid(bool), format("Expected a bool not a '%s'",
				v.type.stringof));
	return v.get!bool();
}

Path[] extractPaths(Value[] v) {
	return v.map!(it => extractPath(it)).array;
}

SemVer extractSemVer(Value[] v) {
	enforce(v.length == 1, format("Expected a length of 1 not '%u'", v.length));
	return extractSemVer(v.front);
}

SemVer extractSemVer(Value v) {
	return SemVer(extractString(v));
}

Path extractPath(Value[] v) {
	enforce(v.length == 1, format("Expected a length of 1 not '%u'", v.length));
	return extractPath(v.front);
}

Path extractPath(Value v) {
	return Path(extractString(v));
}

TargetType extractTargetType(Value[] v) {
	enforce(v.length == 1, format("Expected a length of 1 not '%u'", v.length));
	return extractTargetType(v.front);
}

TargetType extractTargetType(Value v) {
	return to!TargetType(extractString(v));
}

Dependency extractDependency(Tag t) {
	import std.array : front;
	import dud.pkgdescription.versionspecifier : parseVersionSpecifier;

	Dependency ret;
	enforce(t.values.length == 1, format("Expected length 1 not '%u'",
			t.values.length));
	ret.name = extractString(t.values.front);
	foreach(Attribute it; t.attributes) {
		switch(it.name) {
			case "version":
				ret.version_ = parseVersionSpecifier(extractString(it.value));
				break;
			case "path":
				ret.path = extractPath(it.value);
				break;
			case "optional":
				ret.optional = nullable(extractBool(it.value));
				break;
			case "default":
				ret.default_ = nullable(extractBool(it.value));
				break;
			default:
				throw new Exception(format(
						"Key '%s' is not part of a Dependency declaration",
						it.name));
		}
	}
	return ret;
}
