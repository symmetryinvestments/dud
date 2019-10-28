module dud.pkgdescription.output;

import std.algorithm.iteration : filter, map;
import std.array : appender, array, back, empty, front;
import std.conv : to;
import std.exception : enforce;
import std.format : formattedWrite;
import std.json;
import std.typecons : Nullable;

import dud.path;
import dud.semver;
import dud.pkgdescription;
import dud.pkgdescription.versionspecifier;
import dud.pkgdescription.helper;

@safe pure:

void indent(Out)(auto ref Out o, const size_t indent) {
	foreach(i; 0 .. indent) {
		format(o, "\t");
	}
}

void formatIndent(Out, Args...)(auto ref Out o, const size_t indent, string str,
		Args args)
{
	indent(o, indent);
	formattedWrite(o, str, args);
}

string toJSONString(PackageDescription pkg) {
	auto app = appender!string();
	toJSONString(app, pkg);
	return app.data;
}

void toJSONString(Out)(auto ref Out o, PackageDescription pkg) {
	import dud.utils : assumePure;
	JSONValue jv = pkg.toJSON();
	auto dl = assumePure(&jv.toPrettyString);
	formattedWrite(o, dl(JSONOptions.init));
}

JSONValue toJSON(PackageDescription pkg) {
	JSONValue ret;
	static foreach(mem; __traits(allMembers, PackageDescription)) {{
		enum Mem = PreprocessKey!(mem);
		alias MemType = typeof(__traits(getMember, PackageDescription, mem));

		static if(is(MemType == string)) {{
			string s = __traits(getMember, pkg, mem);
			if(!s.empty) {
				ret[Mem] = s;
			}
		}} else static if(is(MemType == string[])) {{
			string[] ss = __traits(getMember, pkg, mem)
				.filter!(it => !it.empty)
				.array;
			if(!ss.empty) {
				ret[Mem] = JSONValue(ss);
			}
		}} else static if(is(MemType == Path[])) {{
			string[] ss = __traits(getMember, pkg, mem)
				.map!(it => it.path)
				.filter!(it => !it.empty)
				.array;
			if(!ss.empty) {
				ret[Mem] = JSONValue(ss);
			}
		}} else static if(is(MemType == PackageDescription[])) {{
			PackageDescription[] confs = __traits(getMember, pkg, mem);
			if(!confs.empty) {
				ret[Mem] = JSONValue(confs.map!(it => it.toJSON()).array);
			}
		}} else static if(is(MemType == Path)) {{
			string p = __traits(getMember, pkg, mem).path;
			if(!p.empty) {
				ret[Mem] = p;
			}
		}} else static if(is(MemType == Dependency[string])) {{
			Dependency[string] deps = __traits(getMember, pkg, mem);
			if(!deps.empty) {
				JSONValue d;
				foreach(iter; deps.byKeyValue()) {
					d[iter.key] = dependecyToJson(iter.value);
				}
				ret[Mem] = d;
			}
		}} else static if(is(MemType == Nullable!TargetType)) {{
			Nullable!TargetType tt = __traits(getMember, pkg, mem);
			if(!tt.isNull()) {
				ret[Mem] = to!string(tt.get());
			}
		}} else static if(is(MemType == SemVer)) {{
			string v = __traits(getMember, pkg, mem).toString();
			if(!v.empty) {
				ret[Mem] = v;
			}
		}} else static if(is(MemType == AbsoluteNativePath)) {{
			// does not need to be written as it is only used for internal use
		}} else {
			static assert(false, "Unhandeld case " ~ MemType.stringof);
		}
	}}
	return ret;
}

JSONValue dependecyToJson(Dependency dep) {
	JSONValue ret;
	if(dep.isShortFrom()) {
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

private bool isShortFrom(const Dependency d) {
	return !d.version_.isNull()
		&& d.path.isNull()
		&& d.optional.isNull()
		&& d.default_.isNull();
}

string toSDLString(PackageDescription pkg) {
	auto app = appender!string();
	toSDLString(app, pkg);
	return app.data;
}

void toSDLString(Out)(auto ref Out o, PackageDescription pkg) {
}
