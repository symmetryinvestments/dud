module dud.pkgdescription.sdl;

import std.array : array, empty, front, appender, popFront;
import std.algorithm.iteration : map, each, filter;
import std.conv : to;
import std.exception : enforce;
import std.format : format, formattedWrite;
import std.typecons : nullable, Nullable;
import std.range : tee;
import std.stdio;

import dud.pkgdescription;
import dud.semver : SemVer;
import dud.pkgdescription.udas;

import dud.sdlang;

@safe pure:

PackageDescription sdlToPackageDescription(string sdl) @safe {
	auto lex = Lexer(sdl);
	auto parser = Parser(lex);
	Root jv = parser.parseRoot();
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

//
// Output Helper
//

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

//
// Platform
//

void print(Attribute a) {
	debug writeln(a.identifier());
}

void sGetPlatform(AttributeAccessor aa, ref Platform[] pls) {
	pls = aa
		.filter!(a => a.identifier() == "platform")
		.tee!(a => enforce(a.value.value.type == ValueType.str,
			format("platfrom must be string not a '%s' at %s:%s",
				a.value.value.type, a.value.line, a.value.column)
		))
		.map!(a => a.value.value.get!string())
		.map!(s => to!Platform(s))
		.array;
}

//
// Strings, StringsPlatform
//

void sGetStringsPlatform(Tag t, string key, ref Strings ret) {
	StringsPlatform tmp;
	sGetStrings(t.values(), key, tmp.strs);
	sGetPlatform(t.attributes(), tmp.platforms);
	ret.platforms ~= tmp;
}

void stringsPlatformToS(Out)(auto ref Out o, string key, Strings value,
		const size_t indent)
{
	value.platforms.each!(s =>
		formatIndent(o, indent, "%s %(%s %)%(platform=%s %)\n", key, s.strs,
			s.platforms.map!(p => to!string(p)))
	);
}

//
// String, StringPlatform
//

void sGetStringPlatform(Tag t, string key, ref String ret) {
	StringPlatform tmp;
	sGetString(t.values(), key, tmp.str);
	sGetPlatform(t.attributes(), tmp.platforms);
	ret.strs ~= tmp;
}

void stringPlatformToS(Out)(auto ref Out o, string key, String value,
		const size_t indent)
{
	value.strs.each!(s =>
		formatIndent(o, indent, "%s %(platform=%s %)\n", key, s.str,
			s.platforms.map!(p => to!string(p)))
	);
}

//
// string
//

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

void stringToSName(Out)(auto ref Out o, string key, string value,
		const size_t indent)
{
	if(!value.empty && indent == 0) {
		formatIndent(o, indent, "%s \"%s\"\n", key, value);
	}
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
	enforce(!v.empty, format("Can not get element of '%s'", key));
	v.each!(it => ret ~= it.get!string());
}

void stringsToS(Out)(auto ref Out o, string key, string[] values,
		const size_t indent)
{
	if(!values.empty) {
		formatIndent(o, indent, "%s %(%s-, %)\n", key, values);
	}
}

//
// SemVer
//

void sGetSemVer(Tag t, string key, ref SemVer ret) {
	sGetSemVer(t.values(), key, ret);
}

void sGetSemVer(ValueRange v, string key, ref SemVer ver) @safe pure {
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

//
// TargetType
//

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

//
// paths
//

void sGetPaths(Tag t, string key, ref Paths ret) {
	auto v = t.values();
	enforce(!v.empty, "Can not get element of empty range");
	PathsPlatform pp;
	pp.paths = v.map!(it => it.get!string())
		.map!(s => UnprocessedPath(s))
		.array;
	sGetPlatform(t.attributes(), pp.platforms);
	ret.platforms ~= pp;
}

void pathsToS(Out)(auto ref Out o, string key, Paths ps,
		const size_t indent)
{
	ps.platforms.each!(p =>
		formatIndent(o, indent, "%s %(%s %) %(platform=%s, %)\n",
			key, p.paths.map!(it => it.path),
			p.platforms.map!(it => to!string(it)))
	);
}

//
// path
//

void sGetPath(Tag t, string key, ref Path ret) {
	auto v = t.values();
	enforce(!v.empty, "Can not get element of empty range");
	string s = v.front.get!string();
	v.popFront();
	enforce(v.empty, "Expected one path not several");
	PathPlatform pp;
	pp.path = UnprocessedPath(s);
	sGetPlatform(t.attributes(), pp.platforms);
	ret.platforms ~= pp;
}

void pathToS(Out)(auto ref Out o, string key, Path p,
		const size_t indent)
{
	p.platforms.each!(plt =>
		formatIndent(o, indent, "%s \"%s\" %(platform=%s, %)\n", key,
			plt.path.path, plt.platforms.map!(it => to!string(it)))
	);
}

//
// PackageDescription
//

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
		sGetPath(t, key, tmp.path);
		//tmp.path = nullable(Path(vr.front.get!string()));
		//vr.popFront();
		//enforce(vr.empty, "Unexpected second SubPackage path");
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
		if(!sp.path.platforms.empty) {
		sp.path.platforms.each!(p =>
			formatIndent(o, indent, "subPackage \"%s\" %(platform=%s, %)\n",
				p.path.path, p.platforms.map!(it => to!string(it)))
		);
		} else if(!sp.inlinePkg.isNull()) {
			formatIndent(o, indent, "subPackage {\n");
			packageDescriptionToS(o, "SubPackage", sp.inlinePkg.get(),
					indent + 1);
			formatIndent(o, indent, "}\n");
		} else {
			assert(false, "SubPackage without a path of inlinePkg");
		}
	}
}

void sGetDependencies(Tag t, string key, ref Dependency[] ret) {
	sGetDependencies(t.values(), t.attributes(), key, ret);
}

void sGetDependencies(ValueRange v, AttributeAccessor ars, string key,
		ref Dependency[] deps)
{
	import dud.pkgdescription.versionspecifier;
	enforce(!v.empty, "Can not get Dependencies of an empty range");
	string name;
	sGetString(v, key, name);
	Dependency ret;
	sGetPlatform(ars, ret.platforms);
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
				ret.path = UnprocessedPath(it.value.value.get!string());
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
	deps ~= ret;
}

void dependenciesToS(Out)(auto ref Out o, string key, Dependency[] deps,
		const size_t indent)
{
	foreach(value; deps) {
		formatIndent(o, indent, "dependency \"%s\"", value.name);
		if(!value.version_.isNull()) {
			formattedWrite(o, " version=\"%s\"", value.version_.get().orig);
		}
		if(!value.path.path.empty) {
			formattedWrite(o, " path=\"%s\"", value.path.path);
		}
		if(!value.default_.isNull()) {
			formattedWrite(o, " default=%s", value.default_.get());
		}
		if(!value.optional.isNull()) {
			formattedWrite(o, " optional=%s", value.optional.get());
		}
		formattedWrite(o, "%( platform=%s,%)",
			value.platforms.map!(p => to!string(p)));
		formattedWrite(o, "\n");
	}
}
