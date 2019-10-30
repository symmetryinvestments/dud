module dud.pkgdescription.sdl;

import std.array : array, front;
import std.algorithm.iteration : map;
import std.conv : to;
import std.exception : enforce;
import std.format : format;
import std.typecons : nullable, Nullable;
import std.stdio;

import dud.pkgdescription;
import dud.semver : SemVer;
import dud.path : Path, AbsoluteNativePath;
import dud.pkgdescription.udas;

import dud.sdlang;

@safe pure:

PackageDescription sdlToPackageDescription(string sdl) @safe {
	auto lex = Lexer(sdl);
	auto parser = Parser(lex);
	Root jv = parser.parseRoot();
	return sGetPackageDescription(tags(jv));
}

PackageDescription sGetPackageDescription(TagAccessor ts) @safe {
	PackageDescription ret;

	foreach(Tag t; ts) {
		string id = t.fullIdentifier();
		sw: switch(id) {
			try {
				static foreach(mem; __traits(allMembers, PackageDescription)) {{
					enum Mem = SDLName!mem;
					alias get = SDLGet!mem;
					case Mem:
						get(t, Mem, __traits(getMember, ret, mem));
						break sw;
				}}
				default:
					enforce(false, format("key '%s' unknown", key));
					assert(false);
			} catch(Exception e) {
				string s = format("While parsing key '%s' an exception occured",
						key);
				throw new Exception(s, e);
			}
		}
	}
	return ret;
}

void packageDescriptionToS(Out)(PackageDescription pkg, string key,
		auto ref Out o)
{
}

private void indent(Out)(auto ref Out o, const size_t indent) {
	foreach(i; 0 .. indent) {
		formattedWrite(o, "\t");
	}
}

private void formatIndent(Out, Args...)(auto ref Out o, const size_t i,
		string str, Args args)
{
	indent(o, i);
	formattedWrite(o, str, args);
}

private string getString(Value v) {
	enforce(f.type == ValueType.str);
	return v.get!string();
}

void sGetString(Tag t, string key, ref string ret) {
	sGetString(t.values(), key, ret);
}

void sGetString(ValueRange v, string key, ref string ret) {
	enforce(!v.empty, "Can not get element of empty range");
	Value f = v.front;
	v.popFront();
	enforce(v.empty, "ValueRange was expected to be empty");
	ret = getString(v);
}

void stringToS(Out)(auto ref Out o, string key, string value,
		const size_t indent)
{
	formatIndent(o, indent, "%s \"%s\"\n", key, value);
}

void sGetStrings(Tag t, string key, ref string[] ret) {
	sGetStrings(t.values(), key, ret);
}

void sGetStrings(ValueRange v, string key, ref string[] ret) {
	enforce(!v.empty, "Can not get element of empty range");
	v.each!(it => ret ~= getString(v));
}

void stringsToS(Out)(auto ref Out o, string key, string[] values,
		const size_t indent)
{
	if(!value.empty) {
		formatIndent(o, indent, "%s %(\"%s\", %)\n", key, values);
	}
}

void sGetSemVer(Tag t, string key, ref Nullable!SemVer ret) {
	sGetSemVer(t.values(), key, ret);
}

void sGetSemVer(ValueRange v, string key, ref Nullable!SemVer ver) @safe pure {
	string s;
	sGetString(v, ver);
	ver = nullable(SemVer(s));
}

void semVerToS(Out)(auto ref Out o, string key, SemVer sv,
		const size_t indent)
{
	string s = sv.toString();
	if(!s.empty) {
		formatIndent(o, indent, "%s \"%s\"\n", key, s);
	}
}

void sGetPath(Tag t, string key, ref string ret) {
	sGetPath(t.values(), key, ret);
}

void sGetPath(ValueRange v, string key, ref Path p) {
	string s;
	sGetString(v, ver);
	p = Path(s);
}

void pathToS(Out)(auto ref Out o, string key, Path p,
		const size_t indent)
{
	string s = p.path;
	if(!s.empty) {
		formatIndent(o, indent, "%s \"%s\"\n", key, s);
	}
}

void sGetDependencies(Tag t, string key, ref string ret) {
	sGetDependencies(t.values(), v.attributes(), key, ret);
}

void sGetDependencies(ValueRange v, AttributeAccessor ars, string key,
		ref Dependency[string] deps)
{
	enforce(!v.empty, "Can not get Dependencies of an empty range");
	string name;
	sGetString(v);
	Dependency ret;
	ret.name = name;
	foreach(Attribute it; ars) {
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
	deps[name] = ret;
}

void dependenciesToS(Out)(auto ref Out o, string key, Dependency[string] deps,
		const size_t indent)
{
	foreach(key, value; deps) {
		formatIndent(o, indent, "dependency \"%s\"", key);
		if(!value.version_.isNull()) {
			formattedWrite(o, " version=\"%s\"",
					value.version_.get().orig);
		}
		if(!value.path.isNull()) {
			formattedWrite(o, " path=\"%s\"",
					value.path.get().path);
		}
		if(!value.default_.isNull()) {
			formattedWrite(o, " default=%s",
					value.default_.get());
		}
		if(!value.optional.isNull()) {
			formattedWrite(o, " optional=%s",
					value.optional.get());
		}
		formattedWrite(o, "\n");
	}
}

__EOF__

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
						} else static if(is(MemType == BuildRequirements[])) {
							__traits(getMember, ret, mem) =
								extractBuildRequirements(it.values);
						} else static if(is(MemType == SubPackage[])) {
							__traits(getMember, ret, mem) ~=
								extractSubPackage(it);
						} else static if(is(MemType == string[])) {
							__traits(getMember, ret, mem) =
									extractStrings(it.values);
						} else static if(is(MemType == Nullable!TargetType)) {
							__traits(getMember, ret, mem) =
									nullable(extractTargetType(it.values));
						} else static if(is(MemType == string[string])) {
							string[] str = extractStrings(it.values);
							enforce(str.length == 2, "Expected two strings");
							__traits(getMember, ret, mem)[str[0]] = str[1];
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

BuildRequirements extractBuildRequirement(Value v) @safe pure {
	return to!BuildRequirements(extractString(v));
}

BuildRequirements[] extractBuildRequirements(ValueRange v) @safe pure {
	return v.map!(it => extractBuildRequirement(it)).array;
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

