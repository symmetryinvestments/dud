module dud.pkgdescription.json;

import std.array : array;
import std.algorithm.iteration : map, each;
import std.json;
import std.format : format;
import std.exception : enforce;
import std.typecons : nullable, Nullable;

import dud.pkgdescription : Dependency, PackageDescription, TargetType;
import dud.semver : SemVer;
import dud.path : Path, AbsoluteNativePath;

@safe pure:

PackageDescription jsonToPackageDescription(string js) {
	JSONValue jv = parseJSON(js);
	return jsonToPackageDescription(jv);
}

PackageDescription jsonToPackageDescription(JSONValue js) {
	import dud.pkgdescription.helper : PreprocessKey;
	enforce(js.type == JSONType.object, "Expected and object");

	PackageDescription ret;

	foreach(string key, ref JSONValue value; js.objectNoRef()) {
		sw: switch(key) {
			try {
			static foreach(mem; __traits(allMembers, PackageDescription)) {{
				enum Mem = PreprocessKey!(mem);
				case Mem: {
					alias MemType = typeof(
							__traits(getMember, PackageDescription, mem));
					static if(is(MemType == string)) {
						__traits(getMember, ret, mem) = extractString(value);
					} else static if(is(MemType == Nullable!SemVer)) {
						__traits(getMember, ret, mem) =
							nullable(extractSemVer(value));
					} else static if(is(MemType == Path)) {
						__traits(getMember, ret, mem) = extractPath(value);
					} else static if(is(MemType == Path[])) {
						__traits(getMember, ret, mem) = extractPaths(value);
					} else static if(is(MemType == string[])) {
						__traits(getMember, ret, mem) = extractStrings(value);
					} else static if(is(MemType == Dependency[string])) {
						__traits(getMember, ret, mem) = extractDependencies(value);
					} else static if(is(MemType == PackageDescription[])) {
						__traits(getMember, ret, mem) = extractPackageDescriptions(value);
					} else static if(is(MemType == Nullable!TargetType)) {
						__traits(getMember, ret, mem) =
							nullable(extractTargetType(value));
					} else static if(is(MemType == AbsoluteNativePath)) {
						// this is ignored
					} else {
						static assert(false, MemType.stringof);
					}
					break sw;
				}
			}}
			default:
				enforce(false, format("key '%s' unknown", key));
				assert(false);
		} catch(Exception e) {
			string s = format("While parsing key '%s' an exception occured", key);
			throw new Exception(s, e);
		}
		}
	}
	return ret;
}

string[] extractStrings(ref JSONValue jv) {
	enforce(jv.type == JSONType.array,
			format("Expected an array not a %s", jv.type));
	return jv.arrayNoRef().map!(it => extractString(it)).array;
}

string extractString(ref JSONValue jv) {
	enforce(jv.type == JSONType.string,
			format("Expected a string not a %s", jv.type));
	return jv.str();
}

bool extractBool(ref JSONValue jv) {
	enforce(jv.type == JSONType.true_ || jv.type == JSONType.false_,
			format("Expected a boolean not a %s", jv.type));
	return jv.boolean();
}

private void insert(ref Dependency[string] ret, Dependency nd) {
	ret[nd.name] = nd;
}

private Dependency depFromJSON(T)(ref T it) {
	Dependency t = extractDependency(it.value);
	t.name = it.key;
	return t;
}

Dependency[string] extractDependencies(ref JSONValue jv) {
	import std.stdio;
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

Dependency extractDependency(ref JSONValue jv) {
	enforce(jv.type == JSONType.object || jv.type == JSONType.string,
			format("Expected an object or a string not a %s while extracting "
				~ "a dependency", jv.type));
	return jv.type == JSONType.object
		? extractDependencyObj(jv)
		: extractDependencyStr(jv);
}

Dependency extractDependencyStr(ref JSONValue jv) {
	import dud.pkgdescription.versionspecifier : parseVersionSpecifier;

	enforce(jv.type == JSONType.string,
			format("Expected an string not a %s while extracting a dependency",
				jv.type));

	Dependency ret;
	ret.version_ = parseVersionSpecifier(jv.str());
	return ret;
}

Dependency extractDependencyObj(ref JSONValue jv) {
	import dud.pkgdescription.versionspecifier : parseVersionSpecifier;

	enforce(jv.type == JSONType.object,
			format("Expected an object not a %s while extracting a dependency",
				jv.type));

	Dependency ret;
	foreach(key, value; jv.objectNoRef()) {
		switch(key) {
			case "version":
				ret.version_ = parseVersionSpecifier(extractString(value));
				break;
			case "path":
				ret.path = extractPath(value);
				break;
			case "optional":
				ret.optional = nullable(extractBool(value));
				break;
			case "default":
				ret.default_ = nullable(extractBool(value));
				break;
			default:
				throw new Exception(format(
						"Key '%s' is not part of a Dependency declaration",
						key));
		}
	}

	return ret;
}

PackageDescription[] extractPackageDescriptions(ref JSONValue jv) {
	enforce(jv.type == JSONType.array,
			format("Expected an array not a %s", jv.type));
	return jv.arrayNoRef().map!(it => jsonToPackageDescription(it)).array;
}

SemVer extractSemVer(ref JSONValue jv) {
	string s = extractString(jv);
	return SemVer(s);
}

Path[] extractPaths(ref JSONValue jv) {
	enforce(jv.type == JSONType.array,
			format("Expected an array not a %s", jv.type));
	return jv.arrayNoRef().map!(it => extractPath(it)).array;
}

Path extractPath(ref JSONValue jv) {
	string s = extractString(jv);
	return Path(s);
}

TargetType extractTargetType(ref JSONValue jv) {
	import std.conv : to;
	string s = extractString(jv);
	return to!TargetType(s);
}
