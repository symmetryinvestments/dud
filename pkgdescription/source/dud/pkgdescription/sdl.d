module dud.pkgdescription.sdl;

import std.array : array, front;
import std.algorithm.iteration : map;
import std.conv : to;
import std.exception : enforce;
import std.format : format;
import std.typecons : nullable, Nullable;
import std.stdio;

import dud.pkgdescription : Dependency, PackageDescription, TargetType,
	   SubPackage;
import dud.semver : SemVer;
import dud.path : Path, AbsoluteNativePath;

import dud.sdlang;

PackageDescription sdlToPackageDescription(string sdl) @safe {
	auto lex = Lexer(sdl);
	auto parser = Parser(lex);
	Root jv = parser.parseRoot();
	return sdlToPackageDescription(jv);
}

PackageDescription sdlToPackageDescription(Root t) @safe {
	return sdlToPackageDescription(t.tags);
}

PackageDescription sdlToPackageDescription(Tags input) @safe pure {
	import dud.pkgdescription.helper : PreprocessKey, KeysToSDLCases;

	import std.stdio;

	PackageDescription ret;

	foreach(Tag it; tags(input)) {
		string key = it.fullIdentifier();
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
						} else static if(is(MemType == Nullable!SemVer)) {
							__traits(getMember, ret, mem) =
								nullable(extractSemVer(it.values));
						} else static if(is(MemType == Path)) {
							__traits(getMember, ret, mem) =
								extractPath(it.values);
						} else static if(is(MemType == Path[])) {
							__traits(getMember, ret, mem) =
								extractPaths(it.values);
						} else static if(is(MemType == SubPackage[])) {
							__traits(getMember, ret, mem) ~=
								extractSubPackage(it);
						} else static if(is(MemType == string[])) {
							__traits(getMember, ret, mem) =
									extractStrings(it.values);
						} else static if(is(MemType == Nullable!TargetType)) {
							__traits(getMember, ret, mem) =
									nullable(extractTargetType(it.values));
						} else static if(is(MemType == Dependency[string])) {
							string name = extractString(it.values);
							enforce(name !in __traits(getMember, ret, mem),
								format("Dependency '%s' already exist", name));
							__traits(getMember, ret, mem)[name] =
									extractDependency(it);
						} else static if(is(MemType == AbsoluteNativePath)) {
							// this is ignored
						} else static if(is(MemType == PackageDescription[])) {
							string name = extractString(it.values);
							enforce(it.oc !is null,
									"Configuration must have children");
							enforce(it.oc.tags !is null,
									"Configuration child must have tags");
							PackageDescription t =
								sdlToPackageDescription(it.oc.tags);
							t.name = name;
							__traits(getMember, ret, mem) ~= t;
						} else {
							static assert(false, MemType.stringof);
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

SubPackage extractSubPackage(Tag t) @safe pure {
	SubPackage pkg;
	ValueRange vr = t.values;
	if(!vr.empty) {
		pkg.path = nullable(Path(vr.front.get!string()));
	} else {
		pkg.inlinePkg =	sdlToPackageDescription(t.oc.tags);
	}
	return pkg;
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
