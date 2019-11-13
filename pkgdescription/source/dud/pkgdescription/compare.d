module dud.pkgdescription.compare;

import std.stdio;
import std.array : empty, front;
import std.algorithm.searching : all, any, canFind, find;
import std.traits : Unqual, FieldNameTuple;
import std.typecons : nullable;

import dud.pkgdescription;

@safe pure:

bool areEqual(const PackageDescription a, const PackageDescription b) {
	import dud.semver : SemVer;
	static foreach(mem; FieldNameTuple!PackageDescription) {{
		alias aMemType = typeof(__traits(getMember, a, mem));

		static if(is(aMemType == const(string))
				|| is(aMemType == const(TargetType))
				|| is(aMemType == const(string[]))
			)
		{
			if(__traits(getMember, a, mem) != __traits(getMember, b, mem)) {
				return false;
			}
		} else static if(is(aMemType == const(SemVer))) {
			auto aSem = __traits(getMember, a, mem);
			auto bSem = __traits(getMember, b, mem);
			if(aSem.isUnknown() || bSem.isUnknown()) {
				return aSem.isUnknown() == bSem.isUnknown();
			} else if(aSem != bSem) {
				return false;
			}
		} else static if(is(aMemType == const(Dependency[]))
				|| is(aMemType == const(String))
				|| is(aMemType == const(Strings))
				|| is(aMemType == const(Path))
				|| is(aMemType == const(Paths))
				|| is(aMemType == const(PackageDescription))
				|| is(aMemType == const(PackageDescription[]))
				|| is(aMemType == const(SubPackage[]))
				|| is(aMemType == const(BuildRequirement[]))
				|| is(aMemType == const(SubConfigs))
				|| is(aMemType == const(BuildType[]))
				|| is(aMemType == const(Platform[]))
				|| is(aMemType == const(Platform[][]))
				|| is(aMemType == const(ToolchainRequirement[Toolchain]))
				|| is(aMemType == const(BuildOptions))
			)
		{
			if(!areEqual(__traits(getMember, a, mem),
					__traits(getMember, b, mem)))
			{
				return false;
			}
		} else {
			static assert(false, aMemType.stringof ~ " not handled");
		}
	}}
	return true;
}

//
// ToolchainRequirement
//

bool areEqual(const ToolchainRequirement as, const ToolchainRequirement bs) {
	return as.no == bs.no && as.version_ == bs.version_;
}

bool areEqual(const ToolchainRequirement[Toolchain] as,
		const ToolchainRequirement[Toolchain] bs)
{
	if(as.length != bs.length) {
		return false;
	}

	return aaCmp!simpleCmp(as, bs);
}

//
// BuildOption
//

bool areEqual(const BuildOption[] as, const BuildOption[] bs) {
	if(as.length != bs.length) {
		return false;
	}

	return as.all!(a => canFind(bs, a)) && bs.all!(b => canFind(as, b));
}

//
// BuildOptions[]
//

bool areEqual(const BuildOptions as, const BuildOptions bs) {
	if(!areEqual(as.unspecifiedPlatform, bs.unspecifiedPlatform)) {
		return false;
	}

	return aaCmp!(areEqual)(as.platforms, bs.platforms);
}

bool areEqual(const BuildOptions[] as, const BuildOptions[] bs) {
	if(as.length != bs.length) {
		return false;
	}

	return as.all!(a => canFind(bs, a)) && bs.all!(a => canFind(as, a));
}

//
// BuildType[]
//

bool areEqual(const BuildType as, const BuildType bs) {
	return areEqual(as.platforms, bs.platforms)
		&& as.name == bs.name
		&& areEqual(as.pkg, bs.pkg);
}

bool areEqual(const BuildType[] as, const BuildType[] bs) {
	if(as.length != bs.length) {
		return false;
	}

	return as.all!(a => canFind(bs, a)) && bs.all!(a => canFind(as, a));
}

//
// SubConfigs
//

bool areEqual(const SubConfigs as, const SubConfigs bs) {
	if(as.unspecifiedPlatform.length != bs.unspecifiedPlatform.length) {
		return false;
	}

	if(as.configs.length != bs.configs.length) {
		return false;
	}

	if(!aaCmp!simpleCmp(as.unspecifiedPlatform, bs.unspecifiedPlatform)) {
		return false;
	}

	return aaCmp!(aaCmp!(simpleCmp, const(string[string])))(as.configs, bs.configs);
}

//
// BuildRequirement
//

bool areEqual(const BuildRequirement[] as, const BuildRequirement[] bs) {
	if(as.length != bs.length) {
		return false;
	}

	return as.all!(a => canFind(bs, a)) && bs.all!(a => canFind(as, a));
}


//
// SubPackage
//

bool areEqual(const SubPackage as, const SubPackage bs) {
	if(as.inlinePkg.isNull() != bs.inlinePkg.isNull()) {
		return false;
	}

	return !as.inlinePkg.isNull()
		? areEqual(as.inlinePkg.get(), bs.inlinePkg.get())
		: areEqual(as.path, bs.path);
}

bool areEqual(const SubPackage[] as, const SubPackage[] bs) {
	if(as.length != bs.length) {
		return false;
	}

	return as.all!(a => canFind!areEqual(bs, a))
		&& bs.all!(a => canFind!areEqual(as, a));
}

//
// PackageDescription[]
//

bool areEqual(const PackageDescription[] as, const PackageDescription[] bs) {
	if(as.length != bs.length) {
		return false;
	}

	return as.all!(a => canFind!areEqual(bs, a))
		&& bs.all!(a => canFind!areEqual(as, a));
}

//
// Paths
//

bool areEqual(const PathsPlatform a, const PathsPlatform b) {
	return areEqual(a.platforms, b.platforms) && a.paths == b.paths;
}

bool areEqual(const Paths a, const Paths b) {
	if(a.platforms.length != b.platforms.length) {
		return false;
	}

	return a.platforms.all!(s => canFind!areEqual(b.platforms, s))
		&& b.platforms.all!(s => canFind!areEqual(a.platforms, s));
}

unittest {
	assert(areEqual(Paths.init, Paths.init));
}

unittest {
	Platform[] p1 = [Platform.gnu, Platform.dmd];
	Platform[] p2 = [Platform.dmd, Platform.gnu, Platform.win32];
	PathsPlatform s1 = PathsPlatform(
			[ UnprocessedPath("foobar"), UnprocessedPath("barfoo") ], p1);
	PathsPlatform s2 = PathsPlatform(
			[ UnprocessedPath("barfoo"), UnprocessedPath("foobar") ], p1);
	PathsPlatform s3 = PathsPlatform(
			[ UnprocessedPath("barfoo"), UnprocessedPath("foobar") ], p2);
	PathsPlatform s4 = PathsPlatform(
			[ UnprocessedPath("foobar"), UnprocessedPath("barfoo") ], p2);
	PathsPlatform s5 = PathsPlatform(
			[ UnprocessedPath("barfoo")], p1);
	PathsPlatform s6 = PathsPlatform(
			[ UnprocessedPath("barfoo")], p2);

	assert( areEqual(Paths([s1]), Paths([s1])));
	assert( areEqual(Paths([s1, s2]), Paths([s1, s2])));
	assert( areEqual(Paths([s2, s1]), Paths([s1, s2])));
	assert(!areEqual(Paths([s2, s3]), Paths([s1, s2])));
	assert(!areEqual(Paths([s2, s3, s1]), Paths([s1, s2])));
	assert(!areEqual(Paths([s3]), Paths([s3, s2])));
	assert(!areEqual(Paths([s4]), Paths([s3])));
	assert( areEqual(Paths([s5]), Paths([s5])));
	assert( areEqual(Paths([s6]), Paths([s6])));
	assert(!areEqual(Paths([s5]), Paths([s6])));
}

//
// Path
//

bool areEqual(const PathPlatform a, const PathPlatform b) {
	return areEqual(a.platforms, b.platforms) && a.path == b.path;
}

bool areEqual(const Path a, const Path b) {
	if(a.platforms.length != b.platforms.length) {
		return false;
	}

	return a.platforms.all!(s => canFind!areEqual(b.platforms, s))
		&& b.platforms.all!(s => canFind!areEqual(a.platforms, s));
}

unittest {
	assert(areEqual(Path.init, Path.init));
}

unittest {
	Platform[] p1 = [Platform.gnu, Platform.dmd];
	Platform[] p2 = [Platform.dmd, Platform.gnu, Platform.win32];
	Platform[] p3 = [Platform.dmd, Platform.gnu, Platform.posix];
	PathPlatform s1 = PathPlatform(UnprocessedPath("foobar"), p1);
	PathPlatform s2 = PathPlatform(UnprocessedPath("args"), p1);
	PathPlatform s3 = PathPlatform(UnprocessedPath("args"), p2);
	PathPlatform s4 = PathPlatform(UnprocessedPath("foobar"), p2);
	PathPlatform s5 = PathPlatform(UnprocessedPath("args"), p3);
	PathPlatform s6 = PathPlatform(UnprocessedPath("foobar"), p3);

	assert( areEqual(Path([s1]), Path([s1])));
	assert(!areEqual(Path([s1]), Path([s2])));
	assert(!areEqual(Path([s3]), Path([s2])));
	assert( areEqual(Path([s1, s2]), Path([s2, s1])));
	assert(!areEqual(Path([s1, s2, s1]), Path([s2, s1])));
	assert(!areEqual(Path([s3, s2, s1]), Path([s2, s4, s1])));
	assert(!areEqual(Path([s3, s2, s4]), Path([s2, s3, s5])));
	assert( areEqual(Path([s6, s6, s6]), Path([s6, s6, s6])));
}

//
// Strings
//

bool areEqual(const StringsPlatform a, const StringsPlatform b) {
	return areEqual(a.platforms, b.platforms) && a.strs == b.strs;
}

bool areEqual(const Strings a, const Strings b) {
	if(a.platforms.length != b.platforms.length) {
		return false;
	}

	return a.platforms.all!(s => canFind!areEqual(b.platforms, s))
		&& b.platforms.all!(s => canFind!areEqual(a.platforms, s));
}

unittest {
	Strings a;
	Strings b;
	assert(areEqual(a, b));
}

unittest {
	Platform[] p1 = [Platform.gnu, Platform.dmd];
	Platform[] p2 = [Platform.dmd, Platform.gnu, Platform.win32];
	Platform[] p3 = [Platform.dmd, Platform.gnu, Platform.posix];
	StringsPlatform s1 = StringsPlatform(["Hello World"], p1);
	StringsPlatform s2 = StringsPlatform(["Foobar", "Hello World"], p1);
	StringsPlatform s3 = StringsPlatform(["Hello World"], p2);
	StringsPlatform s4 = StringsPlatform(["Hello World"], p3);

	assert( areEqual(Strings([s1]), Strings([s1])));
	assert(!areEqual(Strings([s1]), Strings([s2])));
	assert( areEqual(Strings([s1, s2]), Strings([s2, s1])));
	assert( areEqual(Strings([s1, s3]), Strings([s3, s1])));
	assert(!areEqual(Strings([s1, s2, s3]), Strings([s2, s1])));
	assert( areEqual(Strings([s1, s2, s3]), Strings([s2, s3, s1])));
	assert(!areEqual(Strings([s4, s2, s1]), Strings([s2, s3, s1])));
	assert(!areEqual(Strings([s1, s2, s1]), Strings([s2, s3, s1])));
	assert(!areEqual(Strings([s4]), Strings([s1])));
}

//
// String
//

bool areEqual(const StringPlatform a, const StringPlatform b) {
	return areEqual(a.platforms, b.platforms) && a.str == b.str;
}

bool areEqual(const String a, const String b) {
	if(a.platforms.length != b.platforms.length) {
		return false;
	}

	return a.platforms.all!(s => canFind!areEqual(b.platforms, s))
		&& b.platforms.all!(s => canFind!areEqual(a.platforms, s));
}

unittest {
	String a;
	String b;
	assert(areEqual(a, b));
}

unittest {
	Platform[] p1 = [Platform.gnu, Platform.dmd];
	Platform[] p2 = [Platform.dmd, Platform.gnu];
	Platform[] p3 = [Platform.dmd, Platform.gnu, Platform.posix];
	StringPlatform s1 = StringPlatform("Hello World", p1);
	StringPlatform s2 = StringPlatform("Hello World", p2);
	StringPlatform s3 = StringPlatform("Hello World", p3);
	StringPlatform s4 = StringPlatform("Hello", p1);

	assert( areEqual(String([s1]), String([s1])));
	assert( areEqual(String([s1, s2]), String([s2, s1])));
	assert(!areEqual(String([s1, s2, s3]), String([s2, s1])));
	assert( areEqual(String([s1, s2, s3]), String([s2, s3, s1])));
	assert(!areEqual(String([s4, s2, s1]), String([s2, s3, s1])));
	assert(!areEqual(String([s1, s2, s1]), String([s2, s3, s1])));
	assert(!areEqual(String([s4]), String([s1])));
}

//
// Dependency
//

bool areEqual(const(Dependency)[] as, const(Dependency)[] bs) {
	if(as.length != bs.length) {
		return false;
	}

	return as.all!(it => canFind!((a, b) => areEqual(a, b))(bs, it))
		&& bs.all!(it => canFind!((a, b) => areEqual(a, b))(as, it));
}

bool areEqual(const ref Dependency a, ref const Dependency b) {
	return a.name == b.name
		&& a.version_.isNull() == b.version_.isNull()
		&& (!a.version_.isNull() ? a.version_ == b.version_ : true)
		&& a.path == b.path
		&& areEqual(a.platforms, b.platforms)
		&& a.optional.isNull() == b.optional.isNull()
		&& (!a.optional.isNull() ? a.optional == b.optional : true)
		&& a.default_.isNull() == b.default_.isNull()
		&& (!a.default_.isNull() ? a.default_ == b.default_ : true);
}

unittest {
	Dependency a;
	Dependency b;
	assert(areEqual(a, b));
	assert(areEqual(b, a));

	a.path = UnprocessedPath("foobar");
	assert(!areEqual(a, b));
	assert(!areEqual(b, a));

	b.path = UnprocessedPath("foobar");
	assert(areEqual(a, b));
	assert(areEqual(b, a));
}

unittest {
	Dependency a;
	a.path = UnprocessedPath("args");
	Dependency b;
	b.path = UnprocessedPath("args2");
	Dependency c;
	c.path = UnprocessedPath("args3");
	c.default_ = nullable(true);

	assert( areEqual([a, b], [b, a]));
	assert(!areEqual([a, b, a], [b, a]));
	assert(!areEqual([a], [a, a]));
	assert(!areEqual([a, b, c], [b, a]));
	assert( areEqual([a, b, c], [b, c, a]));
}

//
// Platform
//

bool areEqual(const Platform[][] a, const Platform[][] b) {
	if(a.length != b.length) {
		return false;
	} else if(a.length == 0) {
		return true;
	}
	auto cmp = (const(Platform)[] a, const(Platform)[] b) => areEqual(a, b);
	return a.all!(it => canFind!cmp(b, it)) && b.all!(it => canFind!cmp(a, it));
}


bool areEqual(const Platform[] a, const Platform[] b) {
	if(a.length != b.length) {
		return false;
	} else if(a.length == 0) {
		return true;
	}
	return a.all!(it => canFind(b, it));
}

unittest {
	Platform[] a;
	Platform[] b;
	assert(areEqual(a, b));
}

unittest {
	Platform[] a;
	Platform[] b = [Platform.gnu];
	assert(!areEqual(a, b));
}

unittest {
	Platform[] a = [Platform.gnu, Platform.bsd];
	Platform[] b = [Platform.bsd, Platform.gnu];
	assert(areEqual(a, b));
}

//
// Helper
//

bool aaCmp(alias cmp, AA)(AA a, AA b) {
	if(a.length != b.length) {
		return false;
	}

	foreach(key, value; a) {
		auto bVal = key in b;
		if(bVal is null) {
			return false;
		}

		if(!cmp(value, *bVal)) {
			return false;
		}
	}

	foreach(key, value; b) {
		auto aVal = key in a;
		if(aVal is null) {
			return false;
		}

		if(!cmp(value, *aVal)) {
			return false;
		}
	}

	return true;
}

bool simpleCmp(T)(auto ref T a, auto ref T b) {
	return a == b;
}
