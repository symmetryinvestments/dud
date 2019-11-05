module dud.pkgdescription.json;

import std.array : array, empty, front, popFront, appender;
import std.algorithm.iteration : map, each, joiner, splitter;
import std.algorithm.mutation : copy;
import std.conv : to;
import std.json;
import std.format : format, formattedWrite;
import std.exception : enforce;
import std.typecons : nullable, Nullable;
import std.string : indexOf;
import std.stdio;

import dud.pkgdescription;
import dud.pkgdescription.udas;
import dud.pkgdescription.versionspecifier;
import dud.semver : SemVer;

@safe pure:

//
// PackageDescription
//

PackageDescription jsonToPackageDescription(string js) {
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
	auto s = key.splitter('-');
	enforce(!s.empty, format("'%s' is an invalid string", key));
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

//
// SemVer
//

JSONValue semVerToJ(SemVer v) {
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
	enforce(jv.type == JSONType.string,
			format("Expected a string not a %s", jv.type));
	return jv.str();
}

JSONValue stringToJ(string s) {
	return s.empty ? JSONValue.init : JSONValue(s);
}

//
// Strings, StringsPlatform
//

void jGetStringsPlatform(ref JSONValue jv, string key, ref Strings output) {
	enforce(jv.type == JSONType.array,
			format("Expected a array not a %s", jv.type));

	StringsPlatform ret;
	ret.strs = jGetStrings(jv);
	ret.platforms = keyToPlatform(key);

	output.platforms ~= ret;
}

void stringsPlatformToJ(Strings s, string key, ref JSONValue output) {
	enforce(output.type == JSONType.object || output.type == JSONType.null_,
		format("Expected an JSONValue of type object not '%s'", output.type));

	s.platforms.each!(it => output[platformKeyToS(key, it.platforms)] =
			JSONValue(it.strs));
}

//
// String, StringPlatform
//

void jGetStringPlatform(ref JSONValue jv, string key, ref String output) {
	enforce(jv.type == JSONType.string,
			format("Expected a string not a %s", jv.type));

	StringPlatform ret;
	ret.str = jv.str();
	ret.platforms = keyToPlatform(key);

	output.strs ~= ret;
}

void stringPlatformToJ(String s, string key, ref JSONValue output) {
	enforce(output.type == JSONType.object || output.type == JSONType.null_,
		format("Expected an JSONValue of type object not '%s'", output.type));

	s.strs.each!(it => output[platformKeyToS(key, it.platforms)] =
			JSONValue(it.str));
}

//
// strings
//

string[] jGetStrings(ref JSONValue jv) {
	enforce(jv.type == JSONType.array,
			format("Expected an array not a %s", jv.type));
	return jv.arrayNoRef().map!(it => jGetString(it)).array;
}

JSONValue stringsToJ(string[] ss) {
	return ss.empty ? JSONValue.init : JSONValue(ss);
}

//
// path
//

void jGetPath(ref JSONValue jv, string key, ref Path output) {
	enforce(jv.type == JSONType.string,
			format("Expected a string not a %s", jv.type));

	PathPlatform ret;
	ret.path = UnprocessedPath(jv.str());
	ret.platforms = keyToPlatform(key);
	output.platforms ~= ret;
}

void pathToJ(Path s, string key, ref JSONValue output) {
	enforce(output.type == JSONType.object || output.type == JSONType.null_,
		format("Expected an JSONValue of type object not '%s'", output.type));

	s.platforms.each!(it => output[platformKeyToS(key, it.platforms)] =
			JSONValue(it.path.path));
}

//
// paths
//

void jGetPaths(ref JSONValue jv, string key, ref Paths output) {
	enforce(jv.type == JSONType.array,
			format("Expected an array not a %s", jv.type));

	PathsPlatform tmp;
	tmp.platforms = keyToPlatform(key);
	tmp.paths = jv.arrayNoRef()
		.map!(j => j.str())
		.map!(s => UnprocessedPath(s)).array;

	output.platforms ~= tmp;
}

void pathsToJ(Paths ss, string key, ref JSONValue output) {
	enforce(output.type == JSONType.object || output.type == JSONType.null_,
		format("Expected an JSONValue of type object not '%s'", output.type));

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
	enforce(jv.type == JSONType.true_ || jv.type == JSONType.false_,
			format("Expected a boolean not a %s", jv.type));
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

		enforce(jv.type == JSONType.string,
				format("Expected an string not a %s while extracting a dependency",
					jv.type));

		Dependency ret;
		ret.version_ = parseVersionSpecifier(jv.str());
		return ret;
	}

	Dependency extractDependencyObj(ref JSONValue jv) pure {
		import dud.pkgdescription.versionspecifier : parseVersionSpecifier;

		enforce(jv.type == JSONType.object,
				format("Expected an object not a %s while extracting a dependency",
					jv.type));

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
		enforce(jv.type == JSONType.object || jv.type == JSONType.string,
				format("Expected an object or a string not a %s while extracting "
					~ "a dependency", jv.type));
		return jv.type == JSONType.object
			? extractDependencyObj(jv)
			: extractDependencyStr(jv);
	}

	enforce(jv.type == JSONType.object,
			format("Expected an object not a %s while extracting dependencies",
				jv.type));

	const ptrdiff_t dash = key.indexOf('-');
	const string noPlatform = dash == -1 ? key : key[0 .. dash];
	Platform[] plts = keyToPlatform(key);
	deps ~= jv.objectNoRef()
		.byKeyValue()
		.map!(it => depFromJSON(it, plts))
		.array;
}

void dependenciesToJ(Dependency[] deps, string key, ref JSONValue jv) {
	JSONValue[string][string] tmp;
	deps.each!(dep => tmp[platformKeyToS(key, dep.platforms)][dep.name] =
		dependencyToJ(dep));
	foreach(key, value; tmp) {
		jv[key] = JSONValue(value);
	}
}

JSONValue dependencyToJ(Dependency dep) {
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
	static foreach(mem; __traits(allMembers, Dependency)) {{
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
			static assert(false, "Unhandeld case " ~ MemType.stringof);
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
	enforce(jv.type == JSONType.object || jv.type == JSONType.string,
			format("Expected an object or a string not a %s while extracting "
				~ "a dependency", jv.type));
	return jv.type == JSONType.object
		? jGetSubpackageObj(jv)
		: jGetSubpackageStr(jv);
}

SubPackage[] jGetSubPackages(ref JSONValue jv) {
	enforce(jv.type == JSONType.array,
			format("Expected an array not a %s", jv.type));
	return jv.arrayNoRef().map!(it => jGetSubPackage(it)).array;
}

JSONValue subPackagesToJ(SubPackage[] sps) {
	if(sps.empty) {
		return JSONValue.init;
	}

	JSONValue[] ret;
	foreach(sp; sps) {
		if(!sp.inlinePkg.isNull()) {
			ret ~= packageDescriptionToJ(sp.inlinePkg.get());
		} else {
			enforce(!sp.path.platforms.empty,
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
	const ptrdiff_t dash = key.indexOf('-');
	const string noPlatform = dash == -1 ? key : key[0 .. dash];

	bt.platforms = keyToPlatform(key);
	bt.name = noPlatform;
	auto p = new PackageDescription;
	*p = jGetPackageDescription(jv);
	bt.pkg = p;
}

void jGetBuildTypes(ref JSONValue jv, string key, ref BuildType[] bts) {
	enforce(jv.type == JSONType.object,
			format("Expected an object not a %s", jv.type));
	foreach(key, value; jv.objectNoRef()) {
		BuildType tmp;
		jGetBuildType(value, key, tmp);
		bts ~= tmp;
	}
}

void buildTypesToJ(BuildType[] bts, string key, ref JSONValue ret) {
	enforce(ret.type == JSONType.object || ret.type == JSONType.null_,
		format("Expected an JSONValue of type object not '%s'", ret.type));
	if(bts.empty) {
		return;
	}

	JSONValue[string] map;
	foreach(value; bts) {
		string name = platformKeyToS(value.name, value.platforms);
		JSONValue tmp = packageDescriptionToJ(*(value.pkg));
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

void buildOptionsToJ(BuildOptions bos, string key, ref JSONValue ret) {
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

JSONValue targetTypeToJ(TargetType t) {
	return t == TargetType.autodetect ? JSONValue.init : JSONValue(to!string(t));
}

//
// PackageDescription
//

PackageDescription[] jGetPackageDescriptions(JSONValue js) {
	enforce(js.type == JSONType.array, "Expected and array");
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
		|| is(T == Paths);
}

PackageDescription jGetPackageDescription(JSONValue js) {
	enforce(js.type == JSONType.object, "Expected and object");

	PackageDescription ret;

	foreach(string key, ref JSONValue value; js.objectNoRef()) {
		ptrdiff_t dash = key.indexOf('-');
		string noPlatform = dash == -1 ? key : key[0 .. dash];
		sw: switch(noPlatform) {
			try {
				static foreach(mem; __traits(allMembers, PackageDescription)) {{
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
					enforce(false, format("noPlatfrom '%s' unknown from key %s",
						noPlatform, key));
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

JSONValue packageDescriptionToJ(PackageDescription pkg) {
	JSONValue ret;
	static foreach(mem; __traits(allMembers, PackageDescription)) {{
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

JSONValue packageDescriptionsToJ(PackageDescription[] pkgs) {
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
	enforce(jv.type == JSONType.array,
			format("Expected an array not a %s", jv.type));
	return jv.arrayNoRef().map!(it => jGetBuildRequirement(it)).array;
}

JSONValue buildRequirementsToJ(BuildRequirement[] brs) {
	return brs.empty
		? JSONValue.init
		: JSONValue(brs.map!(br => to!string(br)).array);
}

//
// string[string][Platform[]]
//

void jGetStringAA(ref JSONValue jv, string key, ref SubConfigs ret)
{
	enforce(jv.type == JSONType.object,
			format("Expected an object not a %s", jv.type));
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

void stringAAToJ(SubConfigs aa, string key, ref JSONValue ret) {
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
