module dud.descriptiongetter.code;

import std.array : array;
import std.exception : enforce;
import std.algorithm.iteration : each, filter, map;
import std.algorithm.searching : canFind;
import std.json;

@safe:

JSONValue getCodeDlangDump() @trusted {
	import std.exception : assumeUnique;
	import std.net.curl;
	import std.zlib;

	auto data = get("https://code.dlang.org/api/packages/dump");

	auto uc = new UnCompress();

	const(void[]) un = uc.uncompress(data);
	return parseJSON(cast(const(char)[])un);
}

JSONValue trimCodeDlangDump(JSONValue old) {
	if(old.type == JSONType.array) {
		return trimArray(old.arrayNoRef());
	} else if(old.type == JSONType.object) {
		return trimObject(old);
	} else {
		return old;
	}
}

JSONValue trimArray(JSONValue[] old) {
	return JSONValue(old.map!(it => trimCodeDlangDump(it)).array);
}

JSONValue trimObject(JSONValue obj) {
	enforce(obj.type == JSONType.object);
	JSONValue ret;
	foreach(key, value; obj.objectNoRef()) {
		if(key == "info") {
			ret["packageDescription"] = value;
		} else if(!canFind(
			[ "readme", "readmeMarkdown", "docFolder"
			, "packageDescriptionFile", "logo", "errors"
			, "categories", "owner", "errors", "stats", "textScore"
			, "updateCounter", "_id", "updatedAt", "commitID", "date"
			, "documentationURL"
			], key))
		{
			ret[key] = trimCodeDlangDump(value);
		}
	}
	return ret;
}
