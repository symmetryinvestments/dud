module dud.pkgdescription.sdl;

import std.array : array, empty, front, appender, popFront;
import std.algorithm.iteration : map, each;
import std.conv : to;
import std.exception : enforce;
import std.format : format, formattedWrite;
import std.typecons : nullable, Nullable;
import std.stdio;

import dud.pkgdescription;
import dud.semver : SemVer;
import dud.path : Path, AbsoluteNativePath;
import dud.pkgdescription.udas;

import dud.sdlang;

@safe pure:

PackageDescription sdlToPackageDescription(string sdl) @safe {
	debug writeln("Lex");
	auto lex = Lexer(sdl);
	debug writeln("Parser");
	auto parser = Parser(lex);
	debug writeln("Parse");
	Root jv = parser.parseRoot();
	debug writeln("toPkg");
	PackageDescription ret;
	sGetPackageDescription(tags(jv), "dub.sdl", ret);
	return ret;
}

void sGetPackageDescription(TagAccessor ts, string key,
		ref PackageDescription ret) @safe
{
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
					enforce(false, format("key '%s' unknown", id));
					assert(false);
			} catch(Exception e) {
				string s = format("While parsing key '%s' an exception occured",
						key);
				throw new Exception(s, e);
			}
		}
	}
}

void packageDescriptionsToS(Out)(auto ref Out o, string key,
		PackageDescription[] pkgs, const size_t indent)
{
	pkgs.each!(it => packageDescriptionToS(o, it.name, it, indent + 1));
}

string packageDescriptionToS(PackageDescription pkg) {
	auto app = appender!string();
	packageDescriptionToS(app, pkg.name, pkg, 0);
	return app.data;
}

void packageDescriptionToS(Out)(auto ref Out o, string key,
		PackageDescription pkg, const size_t indent)
{
	static foreach(mem; __traits(allMembers, PackageDescription)) {{
		enum Mem = SDLName!mem;
		alias put = SDLPut!mem;
		alias MemType = typeof(__traits(getMember, PackageDescription, mem));
		static if(is(MemType : Nullable!Args, Args...)) {
			if(!__traits(getMember, pkg, mem).isNull) {
				put(o, Mem, __traits(getMember, pkg, mem).get(), indent);
			}
		} else {
			put(o, Mem, __traits(getMember, pkg, mem), indent);
		}
	}}
}

void configurationsToS(Out)(auto ref Out o, string key,
		PackageDescription[] pkgs, const size_t indent)
{
	pkgs.each!(pkg => configurationToS(o, key, pkg, indent));
}

void configurationToS(Out)(auto ref Out o, string key,
		PackageDescription pkg, const size_t indent)
{
	formattedWrite(o, "configuration \"%s\" {\n", pkg.name);
	packageDescriptionToS(o, pkg.name, pkg, indent + 1);
	formattedWrite(o, "}\n");
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

void sGetString(Tag t, string key, ref string ret) {
	sGetString(t.values(), key, ret);
}

void sGetString(ValueRange v, string key, ref string ret) {
	enforce(!v.empty, "Can not get element of empty range");
	Value f = v.front;
	v.popFront();
	enforce(v.empty, "ValueRange was expected to be empty");
	ret = f.get!string();
}

void stringToS(Out)(auto ref Out o, string key, string value,
		const size_t indent)
{
	if(!value.empty) {
		formatIndent(o, indent, "%s \"%s\"\n", key, value);
	}
}

void sGetStrings(Tag t, string key, ref string[] ret) {
	sGetStrings(t.values(), key, ret);
}

void sGetStrings(ValueRange v, string key, ref string[] ret) {
	enforce(!v.empty, "Can not get element of empty range");
	v.each!(it => ret ~= it.get!string());
}

void stringsToS(Out)(auto ref Out o, string key, string[] values,
		const size_t indent)
{
	if(!values.empty) {
		formatIndent(o, indent, "%s %(%s-, %)\n", key, values);
	}
}

void sGetSemVer(Tag t, string key, ref Nullable!SemVer ret) {
	sGetSemVer(t.values(), key, ret);
}

void sGetSemVer(ValueRange v, string key, ref Nullable!SemVer ver) @safe pure {
	string s;
	sGetString(v, "SemVer", s);
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

void sGetTargetType(Tag t, string key, ref TargetType ret) {
	sGetTargetType(t.values(), key, ret);
}

void sGetTargetType(ValueRange v, string key, ref TargetType p) {
	string s;
	sGetString(v, "TargetType", s);
	p = to!TargetType(s);
}

void targetTypeToS(Out)(auto ref Out o, string key, TargetType p,
		const size_t indent)
{
	if(p != TargetType.autodetect) {
		formatIndent(o, indent, "%s \"%s\"\n", key, p);
	}
}

void sGetBuildRequirements(Tag t, string key, ref BuildRequirement[] ret) {
	sGetBuildRequirements(t.values(), key, ret);
}

void sGetBuildRequirements(ValueRange v, string key, ref BuildRequirement[] p) {
	enforce(!v.empty, "Can not get element of empty range");
	v.map!(it => it.get!string()).each!(s => p ~= to!BuildRequirement(s));
}

void buildRequirementsToS(Out)(auto ref Out o, string key,
		BuildRequirement[] ps, const size_t indent)
{
	if(!ps.empty) {
		formatIndent(o, indent, "%s %(\"%s\", %)\n", key,
			ps.map!(it => to!string(it)));
	}
}

void sGetSubConfig(Tag t, string key, ref string[string] ret) {
	sGetSubConfig(t.values(), key, ret);
}

void sGetSubConfig(ValueRange v, string key, ref string[string] ret) {
	enforce(!v.empty, "Can not get a subconfig from an empty range");
	string[] tmp;
	sGetStrings(v, key, tmp);
	enforce(tmp.length == 2, format(
		"A SubConfiguration requires 2 strings not %s", tmp));
	enforce(tmp[0] !in ret, format("SubConfiguration for %s is already present",
		tmp[0]));
	ret[tmp[0]] = tmp[1];
}

void subConfigsToS(Out)(auto ref Out o, string key,
		string[string] scf, const size_t indent)
{
	if(!scf.empty) {
		foreach(key, value; scf) {
			formatIndent(o, indent, "subConfiguration \"%s\" \"%s\"\n", key,
				value);
		}
	}
}

void sGetPaths(Tag t, string key, ref Path[] ret) {
	sGetPaths(t.values(), key, ret);
}

void sGetPaths(ValueRange v, string key, ref Path[] p) {
	enforce(!v.empty, "Can not get element of empty range");
	v.map!(it => it.get!string()).each!(s => p ~= Path(s));
}

void pathsToS(Out)(auto ref Out o, string key, Path[] ps,
		const size_t indent)
{
	if(!ps.empty) {
		formatIndent(o, indent, "%s %(%s %)\n", key,
			ps.map!(it => it.path));
	}
}

void sGetPath(Tag t, string key, ref Path ret) {
	sGetPath(t.values(), key, ret);
}

void sGetPath(ValueRange v, string key, ref Path p) {
	string s;
	sGetString(v, key, s);
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

void sGetPackageDescriptions(Tag t, string key,
		ref PackageDescription[] ret) @safe
{
	string n;
	sGetString(t, "name", n);
	PackageDescription tmp;
	tmp.name = n;
	sGetPackageDescription(tags(t.oc), "configuration", tmp);
	enforce(tmp.name == n,
		format("Configuration names must not be changed in OptChild '%s' => '%s'",
			n, tmp.name));
	ret ~= tmp;
}

void sGetSubPackage(Tag t, string key, ref SubPackage[] ret) {
	ValueRange vr = t.values();
	SubPackage tmp;
	if(!vr.empty) {
		tmp.path = nullable(Path(vr.front.get!string()));
		vr.popFront();
		enforce(vr.empty, "Unexpected second SubPackage path");
	} else {
		PackageDescription iTmp;
		sGetPackageDescription(tags(t.oc), key, iTmp);
		tmp.inlinePkg = nullable(iTmp);
	}
	ret ~= tmp;
}

void subPackagesToS(Out)(auto ref Out o, string key, SubPackage[] sps,
		const size_t indent)
{
	foreach(sp; sps) {
		if(!sp.path.isNull()) {
			formatIndent(o, indent, "subPackage \"%s\"\n",
				sp.path.get());
		} else if(!sp.inlinePkg.isNull()) {
			formatIndent(o, indent, "subPackage \"%s\" {\n");
			packageDescriptionToS(o, "SubPackage", sp.inlinePkg.get(),
					indent + 1);
			formatIndent(o, indent, "}\n");
		} else {
			assert(false, "SubPackage without a path of inlinePkg");
		}
	}
}

void sGetDependencies(Tag t, string key, ref Dependency[string] ret) {
	sGetDependencies(t.values(), t.attributes(), key, ret);
}

void sGetDependencies(ValueRange v, AttributeAccessor ars, string key,
		ref Dependency[string] deps)
{
	import dud.pkgdescription.versionspecifier;
	enforce(!v.empty, "Can not get Dependencies of an empty range");
	string name;
	sGetString(v, key, name);
	Dependency ret;
	ret.name = name;
	foreach(Attribute it; ars) {
		switch(it.identifier()) {
			case "version":
				ret.version_ = it
					.value
					.value
					.get!string()
					.parseVersionSpecifier;
				break;
			case "path":
				ret.path = Path(it.value.value.get!string());
				break;
			case "optional":
				ret.optional = it
					.value
					.value
					.get!bool()
					.nullable;
				break;
			case "default":
				ret.default_ = it
					.value
					.value
					.get!bool()
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

