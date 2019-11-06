module dud.pkgdescription.compare;

import std.array : empty, front;
import std.algorithm.searching : all, any, canFind, find;
import std.traits : Unqual;
import std.typecons : nullable;

import dud.pkgdescription;

@safe pure:

bool areEqual(const PackageDescription a, const PackageDescription b) {
	import dud.semver : SemVer;
	static foreach(mem; __traits(allMembers, PackageDescription)) {{
		alias aMemType = Unqual!(typeof(__traits(getMember, a, mem)));

		static if(is(aMemType == string)
				|| is(aMemType == TargetType)
				|| is(aMemType == SemVer)
				|| is(aMemType == const(string)[])
			)
		{
			if(__traits(getMember, a, mem) != __traits(getMember, b, mem)) {
				return false;
			}
		} else static if(is(aMemType == const(Dependency)[])
				|| is(aMemType == const(String))
			)
		{
			if(!areEqual(__traits(getMember, a, mem),
					__traits(getMember, b, mem)))
			{
				return false;
			}
		} else {
			//static assert(false, aMemType.stringof ~ " not handled");
		}
	}}
	return true;
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
// String
//

bool areEqual(const StringPlatform a, const StringPlatform b) {
	return areEqual(a.platforms, b.platforms) && a.str == b.str;
}

bool areEqual(const String a, const String b) {
	if(a.strs.length != b.strs.length) {
		return false;
	}

	return a.strs.all!(s => canFind!areEqual(b.strs, s))
		&& b.strs.all!(s => canFind!areEqual(a.strs, s));
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
