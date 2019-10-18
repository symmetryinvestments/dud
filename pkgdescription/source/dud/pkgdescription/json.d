module dud.pkgdescription.json;

import std.array : array;
import std.algorithm.iteration : map;
import std.json;
import std.format : format;
import std.exception : enforce;

import dud.pkgdescription : PackageDescription, TargetType;
import dud.semver : SemVer;
import dud.path : Path;

@safe pure:

PackageDescription jsonToPackageDescription(string js) {
	JSONValue jv = parseJSON(js);
	return jsonToPackageDescription(jv);
}

PackageDescription jsonToPackageDescription(JSONValue js) {
	enforce(js.type == JSONType.object, "Expected and object");

	PackageDescription ret;

	foreach(string key, ref JSONValue value; js.objectNoRef()) {
		switch(key) {
			static foreach(mem; __traits(allMembers, PackageDescription)) {
				case mem: {
					alias MemType = typeof(__traits(getMember, PackageDescription, mem));
					static if(is(MemType == string)) {
						__traits(getMember, ret, mem) = extractString(value);
					} else static if(is(MemType == SemVer)) {
						__traits(getMember, ret, mem) = extractSemVer(value);
					} else static if(is(MemType == Path)) {
						__traits(getMember, ret, mem) = extractPath(value);
					} else static if(is(MemType == string[])) {
						__traits(getMember, ret, mem) = extractStringArray(value);
					} else static if(is(MemType == PackageDescription[])) {
						__traits(getMember, ret, mem) = extractPackageDescriptions(value);
					} else static if(is(MemType == TargetType)) {
						__traits(getMember, ret, mem) = extractTargetType(value);
					} else {
						static assert(false, MemType.stringof);
					}
				}
			}
			default:
				enforce(false, format("key '%s' unknown", key));
				assert(false);
		}
	}
	return ret;
}

string[] extractStringArray(ref JSONValue jv) {
	enforce(jv.type == JSONType.array, 
			format("Expected an array not a %s", jv.type));
	return jv.arrayNoRef().map!(it => extractString(it)).array;
}

string extractString(ref JSONValue jv) {
	enforce(jv.type == JSONType.string, 
			format("Expected a string not a %s", jv.type));
	return jv.str();
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

Path extractPath(ref JSONValue jv) {
	string s = extractString(jv);
	return Path(s);
}

TargetType extractTargetType(ref JSONValue jv) {
	import std.conv : to;
	string s = extractString(jv);
	return to!TargetType(s);
}
