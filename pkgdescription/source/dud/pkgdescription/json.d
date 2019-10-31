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
	return input
		.map!(it => it == "unittest"
				? "unittest_"
				: it == "assert"
					? "assert_"
					: it
		)
		.map!(it => to!Platform(it))
		.array;
}

void platformToS(Out)(auto ref Out o, Platform[] p) {
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

string platformKeyToS(string key, Platform[] p) {
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
	return JSONValue(v.toString());
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
	enforce(output.type == JSONType.object,
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
	enforce(output.type == JSONType.object,
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
	enforce(output.type == JSONType.object,
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

Dependency[string] jGetDependencies(ref JSONValue jv) {
	void insert(ref Dependency[string] ret, Dependency nd) pure {
		ret[nd.name] = nd;
	}

	Dependency depFromJSON(T)(ref T it) pure {
		Dependency t = extractDependency(it.value);
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
			ptrdiff_t dash = key.indexOf('-');
			string noPlatform = dash == -1 ? key : key[0 .. dash];
			switch(noPlatform) {
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

	Dependency[string] ret;
	jv.objectNoRef()
		.byKeyValue()
		.map!(it => depFromJSON(it))
		.each!(it => insert(ret, it));
	return ret;
}

JSONValue dependenciesToJ(Dependency[string] deps) {
	JSONValue ret;
	foreach(key, value; deps) {
		ret[key] = dependencyToJ(value);
	}
	return ret;
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
		}} else {
			static assert(false, "Unhandeld case " ~ MemType.stringof);
		}
	}}
	return ret;
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
		|| is(T == Path)
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
// SubPackage
//

SubPackage jGetSubpackageStr(ref JSONValue jv) {
	SubPackage ret;
	jGetPath(jv, "", ret.path);
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

JSONValue subPackagesToJ(SubPackage[] sp) {
	return JSONValue.init;
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

JSONValue buildRequirementsToJ(BuildRequirement[] br) {
	return JSONValue.init;
}

//
// string[string]
//

string[string] jGetStringAA(ref JSONValue jv) {
	enforce(jv.type == JSONType.object,
			format("Expected an object not a %s", jv.type));
	string[string] ret;
	foreach(key, value; jv.objectNoRef()) {
		ret[key] = value.str();
	}
	return ret;
}

JSONValue stringAAToJ(string[string] aa) {
	return aa.empty ? JSONValue.init : JSONValue(aa);
}
