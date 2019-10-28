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

PackageDescription sdlToPackageDescription(string sdl) @safe {
	auto lex = Lexer(sdl);
	auto parser = Parser(lex);
	Root jv = parser.parseRoot();
	return sdlToPackageDescription(jv);
}

PackageDescription sdlToPackageDescription(Root t) @safe {
	import dud.pkgdescription.helper : PreprocessKey, KeysToSDLCases;

	import std.stdio;

	PackageDescription ret;

	foreach(Tag it; tags(t)) {
		string key = it.identifier();
		//writefln("%s", key);
		try {
			sw: switch(key) {
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
					enforce(false, format("key '%s' unknown", key));
					assert(false);
			}
		} catch(Exception e) {
			string s = format("While parsing key '%s' an exception occured",
					it.identifier());
			throw new Exception(s, e);
		}

	}
	return ret;
}

string[] extractStrings(ValueRange v) @safe pure {
	return v.map!(it => extractString(it)).array;
}

string extractString(ValueRange v) @safe pure {
	enforce(!v.empty, "Can not get element of empty range");
	return extractString(v.front);
}

string extractString(Value v) @safe pure {
	enforce(v.type == ValueType.str, format(
		"Expected a string not a '%s'", v.type));
	return v.get!string();
}

bool extractBool(ValueRange v) @safe pure {
	enforce(!v.empty, "Can not get element of empty range");
	return extractBool(v.front);
}

bool extractBool(Value v) @safe pure {
	enforce(v.type == ValueType.boolean,
		format("Expected a bool not a '%s'", v.type));
	return v.get!bool();
}

Path[] extractPaths(Values v) @safe pure {
	return extractPaths(v.values());
}

Path[] extractPaths(ValueRange v) @safe pure {
	return v.map!(it => extractPath(it)).array;
}

Path extractPath(ValueRange v) @safe pure {
	enforce(!v.empty, "Can not get element of empty range");
	return Path(extractString(v.front));
}

Path extractPath(Value v) @safe pure {
	return Path(extractString(v));
}

SemVer extractSemVer(ValueRange v) @safe pure {
	enforce(!v.empty, "Can not get element of empty range");
	return extractSemVer(v.front);
}

SemVer extractSemVer(Value v) @safe pure {
	return SemVer(extractString(v));
}

TargetType extractTargetType(ValueRange v) @safe pure {
	enforce(!v.empty, "Can not get element of empty range");
	return extractTargetType(v.front);
}

TargetType extractTargetType(Value v) @safe pure {
	return to!TargetType(extractString(v));
}

Dependency extractDependency(Tag t) @safe pure {
	import std.array : front;
	import dud.pkgdescription.versionspecifier : parseVersionSpecifier;

	Dependency ret;
	enforce(!t.values().empty, "Can not get element of empty range");
	ret.name = extractString(t.values());
	foreach(Attribute it; t.attributes()) {
		switch(it.identifier()) {
			case "version":
				ret.version_ = it
					.value
					.value
					.extractString
					.parseVersionSpecifier;
				break;
			case "path":
				ret.path = it.value.value.extractPath;
				break;
			case "optional":
				ret.optional = it
					.value
					.value
					.extractBool
					.nullable;
				break;
			case "default":
				ret.default_ = it
					.value
					.value
					.extractBool
					.nullable;
				break;
			default:
				throw new Exception(format(
					"Key '%s' is not part of a Dependency declaration",
					it.identifier()));
		}
	}
	return ret;
}
