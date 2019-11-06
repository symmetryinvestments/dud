module dud.pkgdescription.helper;

import dud.pkgdescription : PackageDescription;

template PreprocessKey(string key) {
	import std.algorithm.searching : endsWith;
	static if(key.endsWith("_")) {
		enum PreprocessKey = key[0 .. $ - 1];
	} else {
		enum PreprocessKey = key;
	}
}

string pkgCompare(const PackageDescription a, const PackageDescription b) {
	import std.typecons : Nullable;
	import std.format : formattedWrite;
	import std.array : appender;
	import std.traits : isArray, FieldNameTuple;

	auto app = appender!string();
	formattedWrite(app, "PackageDescription difference {\n");
	static foreach(mem; FieldNameTuple!PackageDescription) {{
		auto aMem = __traits(getMember, a, mem);
		auto bMem = __traits(getMember, b, mem);

		if(aMem != bMem) {
			static if(is(typeof(aMem) : Nullable!Args, Args...)) {
				if(aMem.isNull() != bMem.isNull()) {
					formattedWrite(app, "\ta.%1$s %s b.%1$s %s\n",
						mem,
						aMem.isNull() ? "null" : "notNull",
						bMem.isNull() ? "null" : "notNull"
					);
				} else {
					assert(false, "This can not happen");
				}
			} else static if(isArray!(typeof(aMem))) {
				if(aMem.length != bMem.length) {
					formattedWrite(app, "a.length(%s) != b.length(%s)\n",
						aMem.length, bMem.length);
				} else {
					formattedWrite(app, "\t%s {\n", mem);
					foreach(idx; 0 .. aMem.length) {
						if(aMem[idx] != bMem[idx]) {
							formattedWrite(app,
								"\t\ta[%s] = %s\n\t\tb[%s] = %s\n",
								idx, aMem[idx], idx, bMem[idx]);
						}
					}
					formattedWrite(app, "\t}\n");
				}
			} else {
				formattedWrite(app, "\ta.%s = %s\nb.%s = %s\n",
					mem, aMem, mem, bMem);
			}
		}
	}}
	formattedWrite(app, "}\n");
	return app.data;
}
