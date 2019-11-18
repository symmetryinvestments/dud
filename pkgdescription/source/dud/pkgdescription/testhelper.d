module dud.pkgdescription.testhelper;

import std.json;
import std.stdio;
import std.format;
import dud.pkgdescription;

@safe:

enum TestFailKind {
	fromJsonOrig,
	fromSDLOrig,
	toJson,
	toSDL,
	fromJsonCopy,
	fromSDLCopy,
	validate,
	cmp
}

package void unRollException(Exception e, string f) {
	import std.stdio : writefln;

	Throwable en = e;
	writefln("%s", f);
	while(en.next !is null) {
		en = en.next;
	}
	writefln("%s", en.msg);
}

JSONValue testToJson(PackageDescription pkg, string f,
		ref size_t[TestFailKind] failCnt)
{
	import dud.pkgdescription.output : toJSON;
	try {
		return toJSON(pkg);
	} catch(Exception e) {
		unRollException(e, f);
		incrementFailCnt(failCnt, TestFailKind.toJson);
	}
	return JSONValue.init;
}

void incrementFailCnt(ref size_t[TestFailKind] aa, TestFailKind tfk) pure {
	size_t* p = tfk in aa;
	if(p !is null) {
		(*p)++;
	} else {
		aa[tfk] = 1;
	}
}

bool fromJsonTest(JSONValue js, ref const(PackageDescription) pkg,
		string f, ref size_t[TestFailKind] failCnt) {
	try {
		PackageDescription nPkg = jsonToPackageDescription(js);
		assert(pkg == nPkg,
			() @trusted {
				return format("%s\nexp:\n%s\ngot:\n%s", f, pkg, nPkg);
			}());
		return true;
	} catch(Exception e) {
		unRollException(e, f);
		incrementFailCnt(failCnt, TestFailKind.fromJsonCopy);
	}
	return false;
}

PackageDescription ddupTest(ref const(PackageDescription) old, string f,
		ref size_t[TestFailKind] failCnt)
{
	import dud.pkgdescription.duplicate : ddup = dup;
	import dud.pkgdescription.validation;
	import dud.pkgdescription.exception;
	PackageDescription copy = ddup(old);
	try {
		validate(copy);
	} catch(ValidationException ve) {
		unRollException(ve, f);
		incrementFailCnt(failCnt, TestFailKind.validate);
	}
	return copy;
}

string testToSDL(PackageDescription pkg, string f,
		ref size_t[TestFailKind] failCnt)
{
	import dud.pkgdescription.output : toSDL;
	try {
		return toSDL(pkg);
	} catch(Exception e) {
		unRollException(e, f);
		incrementFailCnt(failCnt, TestFailKind.toSDL);
	}
	return "";
}
