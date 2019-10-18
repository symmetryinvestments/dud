module dud.pkgdescription.json;

import std.json;
import std.format : format;
import std.exception : enforce;

import dud.pkgdescription : PackageDescription;

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

string extractString(ref JSONValue jv) {
	enforce(jv.type == JSONType.string, 
			format("Expected a string not a %s", jv.type));
	return jv.str();
}
