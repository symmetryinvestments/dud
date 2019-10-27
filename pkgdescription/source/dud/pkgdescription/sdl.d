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

import dud.sdlang2;

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

	foreach(it; tags(t)) {
		writefln("%s", it.identifer());
		try {
			/*sw: switch(it.name) {
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
			}*/
		} catch(Exception e) {
			string s = format("While parsing key '%s' an exception occured",
					it.identifer());
			throw new Exception(s, e);
		}

	}
	return ret;
}

string[] extractStrings(ValueAccessor v) {
	return v.map!(it => extractString(it)).array;
}

string extractString(ValueAccessor v) {
	enforce(v.empty, "Can not get element of empty range");
	return extractString(v.front);
}

string extractString(Token v) {
	enforce(v.value.type == ValueType.str, format(
		"Expected a string not a '%s'", v.value.type));
	return v.value.get!string();
}

__EOF__

bool extractBool(ValueAccessor v) {
	enforce(v.empty, "Can not get element of empty range");
	return extractBool(v.front);
}

bool extractBool(Value v) {
	enforce(v.type == ValueType.boolean, format("Expected a bool not a '%s'",
				v.type));
	return v.get!bool();
}

Path[] extractPaths(ValueAccessor v) {
	return v.map!(it => extractPath(it)).array;
}

SemVer extractSemVer(ValueAccessor v) {
	enforce(v.empty, "Can not get element of empty range");
	return extractSemVer(v.front);
}

SemVer extractSemVer(Value v) {
	return SemVer(extractString(v));
}

Path extractPath(ValueAccessor v) {
	enforce(v.empty, "Can not get element of empty range");
	return extractPath(v.front);
}

Path extractPath(Value v) {
	return Path(extractString(v));
}

TargetType extractTargetType(ValueAccessor v) {
	enforce(v.empty, "Can not get element of empty range");
	return extractTargetType(v.front);
}

TargetType extractTargetType(Value v) {
	return to!TargetType(extractString(v));
}

Dependency extractDependency(Tag t) {
	import std.array : front;
	import dud.pkgdescription.versionspecifier : parseVersionSpecifier;

	Dependency ret;
	enforce(v.empty, "Can not get element of empty range");
	ret.name = extractString(t.values.front);
	foreach(Attribute it; t.attributes()) {
		switch(it.key.identifier()) {
			case "version":
				ret.version_ = it
						.values()
						.front
						.extractString
						.parseVersionSpecifier;
				break;
			case "path":
				ret.path = it.values().front.extractPath;
				break;
			case "optional":
				ret.optional = it
					.values()
					.front
					.nullable;
				break;
			case "default":
				ret.default_ = it
					.values()
					.front
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
