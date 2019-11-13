module dud.pkgdescription.json;

import std.algorithm.iteration : map, each, joiner, splitter;
import std.algorithm.mutation : copy;
import std.algorithm.searching : canFind, startsWith;
import std.array : array, empty, front, popFront, appender;
import std.conv : to;
import std.exception : enforce;
import std.format : format, formattedWrite;
import std.json;
import std.range : tee;
import std.stdio;
import std.string : indexOf;
import std.typecons : nullable, Nullable, tuple;
import std.traits : FieldNameTuple;

import dud.pkgdescription.exception;
import dud.pkgdescription.outpututils;
import dud.pkgdescription.udas;
import dud.pkgdescription.versionspecifier;
import dud.pkgdescription;
import dud.semver : SemVer;

@safe pure:

//
// PackageDescription
//

PackageDescription jsonToPackageDescription(string js) {
	import std.encoding : getBOM, BOM, BOMSeq;
	immutable(BOMSeq) bom = () @trusted {
		return getBOM(cast(ubyte[])js);
	}();
	js = js[bom.sequence.length .. $];

	JSONValue jv = parseJSON(js);
	return jGetPackageDescription(jv);
}

PackageDescription jsonToPackageDescription(JSONValue jv) {
	return jGetPackageDescription(jv);
}

//
// Platform
//

Platform[] keyToPlatform(string key) {
	auto s = key.startsWith("-")
		? key[1 .. $].splitter('-')
		: key.splitter('-');
	enforce!EmptyInput(!s.empty, format("'%s' is an invalid key", key));
	s.popFront();
	return toPlatform(s);
}

Platform[] toPlatform(In)(ref In input) {
	import std.algorithm.sorting : sort;
	import std.algorithm : uniq;

	return input
		.map!(it => it == "unittest"
				? "unittest_"
				: it == "assert"
					? "assert_"
					: it
		)
		.map!(it => to!Platform(it))
		.array
		.sort
		.uniq
		.array;
}

void platformToS(Out)(auto ref Out o, const(Platform)[] p) {
	p
		.map!(it => it == Platform.unittest_
				? "unittest"
				: it == Platform.assert_
					? "assert"
					: to!string(it)
		)
		.map!(s => to!string(s))
		.joiner("-")
		.copy(o);
}

string platformKeyToS(string key, const(Platform)[] p) {
	auto app = appender!string();
	formattedWrite(app, "%s", key);
	if(!p.empty) {
		app.put('-');
		platformToS(app, p);
	}
	return app.data;
}

Platform[] jGetPlatforms(ref JSONValue jv) {
	typeCheck(jv, [JSONType.array]);

	return jv.arrayNoRef()
		.tee!(it => typeCheck(it, [JSONType.string]))
		.map!(it => it.str())
		.map!(s => to!Platform(s))
		.array;
}

JSONValue platformsToJ(const Platform[] plts) {
	return plts.empty
		? JSONValue.init
		: JSONValue(plts.map!(plt => to!string(plt)).array);
}

//
// SemVer
//

JSONValue semVerToJ(const SemVer v) {
	return v.toString().empty
		? JSONValue.init
		: JSONValue(v.toString());
}

SemVer jGetSemVer(ref JSONValue jv) {
	string s = jGetString(jv);
	return SemVer(s);
}

//
// string
//

string jGetString(ref JSONValue jv) {
	typeCheck(jv, [JSONType.string]);
	return jv.str();
}

JSONValue stringToJ(const string s) {
	return s.empty ? JSONValue.init : JSONValue(s);
}

//
// Strings, StringsPlatform
//

void jGetStringsPlatform(ref JSONValue jv, string key, ref Strings output) {
	typeCheck(jv, [JSONType.array]);

	StringsPlatform ret;
	ret.strs = jGetStrings(jv);
	ret.platforms = keyToPlatform(key);

	output.platforms ~= ret;
}

void stringsPlatformToJ(const Strings s, const string key,
		ref JSONValue output)
{
	typeCheck(output, [JSONType.object, JSONType.null_]);

	s.platforms.each!(delegate(const(StringsPlatform) it) pure @safe {
		string nKey = platformKeyToS(key, it.platforms);
		if(output.type == JSONType.object && nKey in output) {
			throw new ConflictingOutput(format(
				"'%s' already present in output JSON", nKey));
		} else if(output.type == JSONType.object && nKey !in output) {
			output[nKey] = JSONValue(it.strs);
		} else {
			output = JSONValue([nKey : it.strs]);
		}
	});
}

//
// String, StringPlatform
//

void jGetStringPlatform(ref JSONValue jv, string key, ref String output) {
	typeCheck(jv, [JSONType.string]);

	StringPlatform ret;
	ret.str = jv.str();
	ret.platforms = keyToPlatform(key);

	output.platforms ~= ret;
}

void stringPlatformToJ(const String s, const string key, ref JSONValue output) {
	typeCheck(output, [JSONType.object, JSONType.null_]);

	s.platforms.each!(it => output[platformKeyToS(key, it.platforms)] =
			JSONValue(it.str));
}

//
// strings
//

string[] jGetStrings(ref JSONValue jv) {
	typeCheck(jv, [JSONType.array]);
	return jv.arrayNoRef().map!(it => jGetString(it)).array;
}

JSONValue stringsToJ(const string[] ss) {
	return ss.empty
		? JSONValue.init
		: JSONValue(ss.map!(s => s).array);
}

//
// path
//

void jGetPath(ref JSONValue jv, string key, ref Path output) {
	typeCheck(jv, [JSONType.string]);

	PathPlatform ret;
	ret.path = UnprocessedPath(jv.str());
	ret.platforms = keyToPlatform(key);
	output.platforms ~= ret;
}

void pathToJ(const Path s, const string key, ref JSONValue output) {
	typeCheck(output, [JSONType.object, JSONType.null_]);

	s.platforms.each!(it => output[platformKeyToS(key, it.platforms)] =
			JSONValue(it.path.path));
}

//
// paths
//

void jGetPaths(ref JSONValue jv, string key, ref Paths output) {
	typeCheck(jv, [JSONType.array]);

	PathsPlatform tmp;
	tmp.platforms = keyToPlatform(key);
	tmp.paths = jv.arrayNoRef()
		.map!(j => j.str())
		.map!(s => UnprocessedPath(s)).array;

	output.platforms ~= tmp;
}

void pathsToJ(const Paths ss, const string key, ref JSONValue output) {
	typeCheck(output, [JSONType.object, JSONType.null_]);

	ss.platforms
		.each!(pp =>
				output[platformKeyToS(key, pp.platforms)]
					= JSONValue(pp.paths.map!(p => p.path).array)
		);
}

//
// bool
//

bool jGetBool(ref JSONValue jv) {
	typeCheck(jv, [JSONType.true_, JSONType.false_]);
	return jv.boolean();
}

//
// Dependency
//

void jGetDependencies(ref JSONValue jv, string key, ref Dependency[] deps) {
	void insert(ref Dependency[string] ret, Dependency nd) pure {
		ret[nd.name] = nd;
	}

	Dependency depFromJSON(T)(ref T it, Platform[] plts) pure {
		Dependency t = extractDependency(it.value);
		t.platforms = plts;
		t.name = it.key;
		return t;
	}

	Dependency extractDependencyStr(ref JSONValue jv) pure {
		import dud.pkgdescription.versionspecifier : parseVersionSpecifier;

		typeCheck(jv, [JSONType.string]);

		Dependency ret;
		ret.version_ = parseVersionSpecifier(jv.str());
		return ret;
	}

	Dependency extractDependencyObj(ref JSONValue jv) pure {
		import dud.pkgdescription.versionspecifier : parseVersionSpecifier;

		typeCheck(jv, [JSONType.object]);

		Dependency ret;
		foreach(key, value; jv.objectNoRef()) {
			switch(key) {
				case "version":
					ret.version_ = parseVersionSpecifier(jGetString(value));
					break;
				case "path":
					ret.path.path = jGetString(value);
					break;
				case "optional":
					ret.optional = nullable(jGetBool(value));
					break;
				case "default":
					ret.default_ = nullable(jGetBool(value));
					break;
				default:
					throw new Exception(format(
							"Key '%s' is not part of a Dependency declaration",
							key));
			}
		}

		return ret;
	}

	Dependency extractDependency(ref JSONValue jv) pure {
		typeCheck(jv, [JSONType.object, JSONType.string]);
		return jv.type == JSONType.object
			? extractDependencyObj(jv)
			: extractDependencyStr(jv);
	}

	typeCheck(jv, [JSONType.object]);

	const string noPlatform = splitOutKey(key);
	Platform[] plts = keyToPlatform(key);
	deps ~= jv.objectNoRef()
		.byKeyValue()
		.map!(it => depFromJSON(it, plts))
		.array;
}

void dependenciesToJ(const Dependency[] deps, string key, ref JSONValue jv) {
	JSONValue[string][string] tmp;
	deps.each!(dep => tmp[platformKeyToS(key, dep.platforms)][dep.name] =
		dependencyToJ(dep));
	foreach(key, value; tmp) {
		jv[key] = JSONValue(value);
	}
}

JSONValue dependencyToJ(const Dependency dep) {
	import dud.pkgdescription.helper;

	bool isShortFrom(const Dependency d) pure {
		return !d.version_.isNull()
			&& d.path.path.empty
			&& d.optional.isNull()
			&& d.default_.isNull();
	}

	JSONValue ret;
	if(isShortFrom(dep)) {
		return JSONValue(dep.version_.get().orig);
	}
	static foreach(mem; FieldNameTuple!Dependency) {{
		alias MemType = typeof(__traits(getMember, Dependency, mem));
		enum Mem = PreprocessKey!(mem);
		static if(is(MemType == string)) {{
			// no need to handle this, this is stored as a json key
		}} else static if(is(MemType == Nullable!VersionSpecifier)) {{
			Nullable!VersionSpecifier nvs = __traits(getMember, dep, mem);
			if(!nvs.isNull()) {
				ret[Mem] = nvs.get().orig;
			}
		}} else static if(is(MemType == UnprocessedPath)) {{
			UnprocessedPath p = __traits(getMember, dep, mem);
			if(!p.path.empty) {
				ret[Mem] = p.path;
			}
		}} else static if(is(MemType == Nullable!bool)) {{
			Nullable!bool b = __traits(getMember, dep, mem);
			if(!b.isNull()) {
				ret[Mem] = b;
			}
		}} else static if(is(MemType == Platform[])) {{
			// not handled here
		}} else {
			static assert(false, "Unhandeld type " ~ MemType.stringof ~
				" for mem " ~ Mem);
		}
	}}
	return ret;
}

//
// SubPackage
//

SubPackage jGetSubpackageStr(ref JSONValue jv) {
	SubPackage ret;
	PathPlatform pp;
	pp.path.path = jGetString(jv);
	ret.path.platforms ~= pp;
	return ret;
}

SubPackage jGetSubpackageObj(ref JSONValue jv) {
	SubPackage ret;
	ret.inlinePkg = jGetPackageDescription(jv);
	return ret;
}

SubPackage jGetSubPackage(ref JSONValue jv) {
	typeCheck(jv, [JSONType.object, JSONType.string]);
	return jv.type == JSONType.object
		? jGetSubpackageObj(jv)
		: jGetSubpackageStr(jv);
}

SubPackage[] jGetSubPackages(ref JSONValue jv) {
	typeCheck(jv, [JSONType.array]);
	return jv.arrayNoRef().map!(it => jGetSubPackage(it)).array;
}

JSONValue subPackagesToJ(const SubPackage[] sps) {
	if(sps.empty) {
		return JSONValue.init;
	}

	JSONValue[] ret;
	foreach(sp; sps) {
		if(!sp.inlinePkg.isNull()) {
			ret ~= packageDescriptionToJ(sp.inlinePkg.get());
		} else {
			enforce!EmptyInput(!sp.path.platforms.empty,
				"SubPackage entry must be either Package description or path");
			ret ~= stringToJ(sp.path.platforms.front.path.path);
		}
	}
	return JSONValue(ret);
}

//
// BuildType
//

void jGetBuildType(ref JSONValue jv, string key, ref BuildType bt) {
	const string noPlatform = splitOutKey(key);

	bt.platforms = keyToPlatform(key);
	bt.name = noPlatform;
	bt.pkg = jGetPackageDescription(jv);
}

void jGetBuildTypes(ref JSONValue jv, string key, ref BuildType[] bts) {
	typeCheck(jv, [JSONType.object]);
	foreach(key, value; jv.objectNoRef()) {
		BuildType tmp;
		jGetBuildType(value, key, tmp);
		bts ~= tmp;
	}
}

void buildTypesToJ(const BuildType[] bts, const string key, ref JSONValue ret) {
	typeCheck(ret, [JSONType.object, JSONType.null_]);
	if(bts.empty) {
		return;
	}

	JSONValue[string] map;
	foreach(value; bts) {
		string name = platformKeyToS(value.name, value.platforms);
		JSONValue tmp = packageDescriptionToJ(value.pkg);
		map[name] = tmp;
	}
	ret["buildTypes"] = map;
}

//
// BuildOption
//

void jGetBuildOptions(ref JSONValue jv, string key, ref BuildOptions bos) {
	immutable(Platform[]) iPlts = keyToPlatform(key);

	if(iPlts.empty) {
		bos.unspecifiedPlatform = jv.arrayNoRef()
			.map!(it => it.str())
			.map!(s => to!BuildOption(s))
			.array;
	} else {
		bos.platforms[iPlts] = jv.arrayNoRef()
			.map!(it => it.str())
			.map!(s => to!BuildOption(s))
			.array;
	}
}

void buildOptionsToJ(const BuildOptions bos, const string key,
		ref JSONValue ret)
{
	if(!bos.unspecifiedPlatform.empty) {
		JSONValue j = JSONValue(
			bos.unspecifiedPlatform.map!(bo => to!string(bo)).array);
		ret["buildOptions"] = j;
	}

	foreach(plts, value; bos.platforms) {
		ret[platformKeyToS("buildOptions", plts)] =
			JSONValue(value.map!(bo => to!string(bo)).array);
	}
}

//
// TargetType
//

TargetType jGetTargetType(ref JSONValue jv) {
	import std.conv : to;
	string s = jGetString(jv);
	return to!TargetType(s);
}

JSONValue targetTypeToJ(const TargetType t) {
	return t == TargetType.autodetect ? JSONValue.init : JSONValue(to!string(t));
}

//
// PackageDescription
//

PackageDescription[] jGetPackageDescriptions(JSONValue js) {
	typeCheck(js, [JSONType.array]);
	return js.arrayNoRef().map!(it => jGetPackageDescription(it)).array;
}

template isPlatfromDependend(T) {
	enum isPlatfromDependend =
		is(T == String)
		|| is(T == Strings)
		|| is(T == Dependency[])
		|| is(T == Path)
		|| is(T == SubConfigs)
		|| is(T == BuildOptions)
		|| is(T == BuildType[])
		|| is(T == ToolchainRequirement[Toolchain])
		|| is(T == Paths);
}

PackageDescription jGetPackageDescription(JSONValue js) {
	typeCheck(js, [JSONType.object]);

	PackageDescription ret;

	foreach(string key, ref JSONValue value; js.objectNoRef()) {
		const string noPlatform = splitOutKey(key);
		sw: switch(noPlatform) {
			static foreach(mem; FieldNameTuple!PackageDescription) {{
				enum Mem = JSONName!mem;
				alias get = JSONGet!mem;
				alias MemType = typeof(__traits(getMember, ret, mem));
				case Mem:
					static if(isPlatfromDependend!MemType) {
						get(value, key, __traits(getMember, ret, mem));
					} else {
						__traits(getMember, ret, mem) = get(value);
					}
					break sw;
			}}
			default:
				throw new KeyNotHandled(
					key == noPlatform
						? format("The json dud format does not know a key '%s'.",
							key)
						: format("The json dud format does not know a key '%s'."
							~ " Without platform '%s'", key, noPlatform)
				);
		}
	}
	return ret;
}

JSONValue packageDescriptionToJ(const PackageDescription pkg) {
	JSONValue ret;
	static foreach(mem; FieldNameTuple!PackageDescription) {{
		enum Mem = JSONName!mem;
		alias put = JSONPut!mem;
		alias MemType = typeof(__traits(getMember, PackageDescription, mem));
		static if(is(MemType : Nullable!Args, Args...)) {
			if(!__traits(getMember, pkg, mem).isNull) {
				JSONValue tmp = put(__traits(getMember, pkg, mem).get());
				if(tmp.type != JSONType.null_) {
					ret[Mem] = tmp;
				}
			}
		} else {
			static if(isPlatfromDependend!MemType) {
				put(__traits(getMember, pkg, mem), Mem, ret);
			} else {
				JSONValue tmp = put(__traits(getMember, pkg, mem));
				if(tmp.type != JSONType.null_) {
					ret[Mem] = tmp;
				}
			}
		}
	}}
	return ret;
}

JSONValue packageDescriptionsToJ(const PackageDescription[] pkgs) {
	return pkgs.empty
		? JSONValue.init
		: JSONValue(pkgs.map!(it => packageDescriptionToJ(it)).array);
}

//
// BuildRequirement
//

BuildRequirement jGetBuildRequirement(ref JSONValue jv) {
	string s = jGetString(jv);
	return to!BuildRequirement(s);
}

BuildRequirement[] jGetBuildRequirements(ref JSONValue jv) {
	typeCheck(jv, [JSONType.array]);
	return jv.arrayNoRef().map!(it => jGetBuildRequirement(it)).array;
}

JSONValue buildRequirementsToJ(const BuildRequirement[] brs) {
	return brs.empty
		? JSONValue.init
		: JSONValue(brs.map!(br => to!string(br)).array);
}

//
// string[string][Platform[]]
//

void jGetStringAA(ref JSONValue jv, string key, ref SubConfigs ret) {
	typeCheck(jv, [JSONType.object]);
	immutable(Platform[]) platforms = keyToPlatform(key);

	string[string] tmp;
	foreach(pkg, value; jv.objectNoRef()) {
		if(platforms.empty) {
			ret.unspecifiedPlatform[pkg] = value.str();
		} else {
			tmp[pkg] = value.str();
		}
	}
	if(!platforms.empty) {
		ret.configs[platforms] = tmp;
	}
}

void stringAAToJ(const SubConfigs aa, const string key, ref JSONValue ret) {
	JSONValue unspecific;
	aa.unspecifiedPlatform.byKeyValue()
		.each!(it => unspecific[it.key] = it.value);

	if(!aa.unspecifiedPlatform.empty) {
		ret["subConfigurations"] = unspecific;
	}

	foreach(plt, value; aa.configs) {
		JSONValue tmp;
		foreach(pkg, ver; value) {
			tmp[pkg] =ver;
		}
		if(!value.empty) {
			string k = platformKeyToS("subConfigurations", plt);
			ret[k] = tmp;
		}
	}
}

//
// ToolchainRequirement
//

Toolchain jGetToolchain(string s) {
	return to!Toolchain(s);
}

ToolchainRequirement jGetToolchainRequirement(ref JSONValue jv) {
	typeCheck(jv, [JSONType.string]);
	const string s = jv.str;
	return s == "no"
		? ToolchainRequirement(true, VersionSpecifier.init)
		: ToolchainRequirement(false, parseVersionSpecifier(s));
}

void insertInto(const Toolchain tc, const ToolchainRequirement tcr,
		ref ToolchainRequirement[Toolchain] ret)
{
	enforce!ConflictingInput(tc !in ret, format(
			"'%s' is already in '%s'", tc, ret));
	ret[tc] = tcr;
}

void jGetToolchainRequirement(ref JSONValue jv, string key,
		ref ToolchainRequirement[Toolchain] ret)
{
	typeCheck(jv, [JSONType.object]);
	jv.objectNoRef()
		.byKeyValue()
		.map!(it => tuple(it.key.jGetToolchain(),
					jGetToolchainRequirement(it.value)))
		.each!(tup => insertInto(tup[0], tup[1], ret));
}

string toolchainToString(const ToolchainRequirement tcr) {
	return tcr.no ? "no" : tcr.version_.orig;
}

void toolchainRequirementToJ(const ToolchainRequirement[Toolchain] tcrs,
		const string key, ref JSONValue ret)
{
	if(tcrs.empty) {
		return;
	}
	typeCheck(ret, [JSONType.object, JSONType.null_]);

	JSONValue[string] map;
	foreach(key, value; tcrs) {
		map[to!string(key)] = toolchainToString(value);
	}
	ret["toolchainRequirements"] = map;
}

//
// Helper
//

void typeCheck(const JSONValue got, const JSONType[] exp,
		const string file = __FILE__, const size_t line = __LINE__)
{
	assert(!exp.empty);
	if(!canFind(exp, got.type)) {
		throw new WrongTypeJSON(
			exp.length == 1
				? format("Expected a JSONValue of type '%s' but got '%s'",
					exp.front, got.type)
				: format("Expected a JSONValue of types [%(%s, %)]' but got '%s'",
					exp, got.type),
			file, line);
	}
}

string splitOutKey(string key) {
	const ptrdiff_t dash = key.indexOf('-', 1);
	const string noPlatform = dash == -1 ? key : key[0 .. dash];
	return noPlatform;
}

unittest {
	assert(splitOutKey("hello-posix") == "hello");
	assert(splitOutKey("-hello-posix") == "-hello");
	assert(splitOutKey("-hello") == "-hello");
}
