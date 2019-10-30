module dud.pkgdescription.json;

import std.array : array, empty;
import std.algorithm.iteration : map, each;
import std.conv : to;
import std.json;
import std.format : format;
import std.exception : enforce;
import std.typecons : nullable, Nullable;

import dud.pkgdescription;
import dud.pkgdescription.udas;
import dud.pkgdescription.versionspecifier;
import dud.semver : SemVer;
import dud.path : Path, AbsoluteNativePath;

@safe pure:

PackageDescription jsonToPackageDescription(string js) {
	JSONValue jv = parseJSON(js);
	return jGetPackageDescription(jv);
}

JSONValue semVerToJ(SemVer v) {
	return JSONValue(v.toString());
}

SemVer jGetSemVer(ref JSONValue jv) {
	string s = jGetString(jv);
	return SemVer(s);
}

string jGetString(ref JSONValue jv) {
	enforce(jv.type == JSONType.string,
			format("Expected a string not a %s", jv.type));
	return jv.str();
}

JSONValue stringToJ(string s) {
	return s.empty ? JSONValue.init : JSONValue(s);
}

Path jGetPath(ref JSONValue jv) {
	string s = jGetString(jv);
	return Path(s);
}

JSONValue pathToJ(Path s) {
	return s.path.empty ? JSONValue.init : JSONValue(s.path);
}

string[] jGetStrings(ref JSONValue jv) {
	enforce(jv.type == JSONType.array,
			format("Expected an array not a %s", jv.type));
	return jv.arrayNoRef().map!(it => jGetString(it)).array;
}

JSONValue stringsToJ(string[] ss) {
	return ss.empty ? JSONValue.init : JSONValue(ss);
}

Path[] jGetPaths(ref JSONValue jv) {
	enforce(jv.type == JSONType.array,
			format("Expected an array not a %s", jv.type));
	return jv.arrayNoRef().map!(it => jGetPath(it)).array;
}

JSONValue pathsToJ(Path[] ss) {
	return ss.empty ? JSONValue.init : JSONValue(ss.map!(it => it.path).array);
}

bool jGetBool(ref JSONValue jv) {
	enforce(jv.type == JSONType.true_ || jv.type == JSONType.false_,
			format("Expected a boolean not a %s", jv.type));
	return jv.boolean();
}

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
			switch(key) {
				case "version":
					ret.version_ = parseVersionSpecifier(jGetString(value));
					break;
				case "path":
					ret.path = jGetPath(value);
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
			&& d.path.isNull()
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
		}} else static if(is(MemType == Nullable!Path)) {{
			Nullable!Path p = __traits(getMember, dep, mem);
			if(!p.isNull()) {
				string ps = p.get().path;
				if(!ps.empty) {
					ret[Mem] = ps;
				}
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

TargetType jGetTargetType(ref JSONValue jv) {
	import std.conv : to;
	string s = jGetString(jv);
	return to!TargetType(s);
}

JSONValue targetTypeToJ(TargetType t) {
	return t == TargetType.autodetect ? JSONValue.init : JSONValue(to!string(t));
}

PackageDescription[] jGetPackageDescriptions(JSONValue js) {
	enforce(js.type == JSONType.array, "Expected and array");
	return js.arrayNoRef().map!(it => jGetPackageDescription(it)).array;
}

PackageDescription jGetPackageDescription(JSONValue js) {
	enforce(js.type == JSONType.object, "Expected and object");

	PackageDescription ret;

	foreach(string key, ref JSONValue value; js.objectNoRef()) {
		sw: switch(key) {
			try {
				static foreach(mem; __traits(allMembers, PackageDescription)) {{
					enum Mem = JSONName!mem;
					alias get = JSONGet!mem;
					case Mem:
						__traits(getMember, ret, mem) = get(value);
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
			JSONValue tmp = put(__traits(getMember, pkg, mem));
			if(tmp.type != JSONType.null_) {
				ret[Mem] = tmp;
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

SubPackage jGetSubpackageStr(ref JSONValue jv) {
	SubPackage ret;
	ret.path = jGetPath(jv);
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

BuildRequirements jGetBuildRequirement(ref JSONValue jv) {
	string s = jGetString(jv);
	return to!BuildRequirements(s);
}

BuildRequirements[] jGetBuildRequirements(ref JSONValue jv) {
	enforce(jv.type == JSONType.array,
			format("Expected an array not a %s", jv.type));
	return jv.arrayNoRef().map!(it => jGetBuildRequirement(it)).array;
}

JSONValue buildRequirementsToJ(BuildRequirements[] br) {
	return JSONValue.init;
}

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
