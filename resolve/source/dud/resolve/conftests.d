module dud.resolve.conftests;

@safe pure:
import std.format : format;
import std.algorithm.iteration : map, joiner;
import std.exception : enforce;
import core.exception : AssertError;

import dud.resolve.conf;
import dud.resolve.confs;
import dud.resolve.positive;
import dud.semver.versionrange;

private:

const c1 = Conf("foo", IsPositive.yes);
const c2 = Conf("foo", IsPositive.no);
const c3 = Conf("bar", IsPositive.yes);
const c4 = Conf("bar", IsPositive.no);
const c5 = Conf("", IsPositive.yes);
const c6 = Conf("", IsPositive.no);

void testImpl(const(Conf) a, const(Conf) b, const(Confs) exp, const(Confs) rslt,
		int line)
{
	enforce!AssertError(rslt == exp,
		format("\na: %s\nb: %s\nexp: %s\nrsl: %s", a, b, exp, rslt),
		__FILE__, line);
}

void testIntersection(const(Conf) a, const(Conf) b, const(Confs) exp,
		int line = __LINE__)
{
	const(Confs) rslt = intersectionOf(a, b);
	testImpl(a, b, exp, rslt, line);
}

void testDifference(const(Conf) a, const(Conf) b, const(Confs) exp,
		int line = __LINE__)
{
	const(Confs) rslt = differenceOf(a, b);
	testImpl(a, b, exp, rslt, line);
}


//
// differenceOf
//

unittest {
	testDifference(c1, c1, Confs([]));
	testDifference(c1, c2, Confs([c1]));
	testDifference(c1, c3, Confs([c1]));
	testDifference(c1, c4, Confs([c1]));
	testDifference(c1, c5, Confs([c1]));
	testDifference(c1, c6, Confs([c1]));

	testDifference(c2, c1, Confs([c2]));
	testDifference(c2, c2, Confs([]));
	testDifference(c2, c3, Confs([c2]));
	testDifference(c2, c4, Confs([c2]));
	testDifference(c2, c5, Confs([c2]));
	testDifference(c2, c6, Confs([c2]));
}

//
// opCmp
//

unittest {
	assert(c6 < c1);
	assert(c6 < c2);
	assert(c6 < c3);
	assert(c6 < c4);
	assert(c6 < c5);
	assert(c6 >= c6);
	assert(c6 <= c6);

	assert(c5 < c1);
	assert(c5 < c2);
	assert(c5 < c3);
	assert(c5 < c4);
	assert(c5 <= c5);
	assert(c5 >= c5);
	assert(c5 > c6);

	assert(c4 < c1);
	assert(c4 < c2);
	assert(c4 < c3);
	assert(c4 >= c4);
	assert(c4 <= c4);
	assert(c4 > c5);
	assert(c4 > c6);

	assert(c3 < c1);
	assert(c3 < c2);
	assert(c3 >= c3);
	assert(c3 <= c3);
	assert(c3 > c4);
	assert(c3 > c5);
	assert(c3 > c6);

	assert(c2 < c1);
	assert(c2 <= c2);
	assert(c2 >= c2);
	assert(c2 > c3);
	assert(c2 > c4);
	assert(c2 > c5);
	assert(c2 > c6);

	assert(c1 <= c1);
	assert(c1 >= c1);
	assert(c1 > c2);
	assert(c1 > c3);
	assert(c1 > c4);
	assert(c1 > c5);
	assert(c1 > c6);
}

//
// intersectionOf { x : x in A and x in B }
//

unittest {
	testIntersection(c6, c1, Confs([c6]));
	testIntersection(c6, c2, Confs([c6]));
	testIntersection(c6, c3, Confs([c6]));
	testIntersection(c6, c4, Confs([c6]));
	testIntersection(c6, c5, Confs([c6]));
	testIntersection(c6, c6, Confs([c6]));

	testIntersection(c5, c1, Confs([c1]));
	testIntersection(c5, c2, Confs([c2, c5]));
	testIntersection(c5, c3, Confs([c3]));
	testIntersection(c5, c4, Confs([c4, c5]));
	testIntersection(c5, c5, Confs([c5]));
	testIntersection(c5, c6, Confs([c6]));

	testIntersection(c4, c1, Confs([]));
	testIntersection(c4, c2, Confs([]));
	testIntersection(c4, c3, Confs([]));
	testIntersection(c4, c4, Confs([c4]));
	testIntersection(c4, c5, Confs([c4, c5]));
	testIntersection(c4, c6, Confs([c6]));

	testIntersection(c3, c1, Confs([]));
	testIntersection(c3, c2, Confs([]));
	testIntersection(c3, c3, Confs([c3]));
	testIntersection(c3, c4, Confs([]));
	testIntersection(c3, c5, Confs([c3]));
	testIntersection(c3, c6, Confs([c6]));

	testIntersection(c2, c1, Confs([]));
	testIntersection(c2, c2, Confs([c2]));
	testIntersection(c2, c3, Confs([]));
	testIntersection(c2, c4, Confs([]));
	testIntersection(c2, c5, Confs([c2, c5]));
	testIntersection(c2, c6, Confs([c6]));

	testIntersection(c1, c1, Confs([c1]));
	testIntersection(c1, c2, Confs([]));
	testIntersection(c1, c3, Confs([]));
	testIntersection(c1, c4, Confs([]));
	testIntersection(c1, c5, Confs([c1]));
	testIntersection(c1, c6, Confs([c6]));
}

//
// invert
//

void testInvert(const(Conf) inp, const(Conf) exp, const int line = __LINE__) {
	import std.exception : enforce;

	const(Conf) inv = invert(inp);
	enforce!AssertError(inv == exp
			, format("\ninp %s\ninv %s\nexp %s", inp, inv, exp), __FILE__, line);
}

unittest {
	testInvert(c1, c2);
	testInvert(c2, c1);
	testInvert(c3, c4);
	testInvert(c4, c3);
	testInvert(c5, c6);
	testInvert(c6, c5);
}

//
// allowsAny
//

unittest {
	assert( allowsAny(c1, c1));
	assert(!allowsAny(c1, c2));
	assert(!allowsAny(c1, c3));
	assert(!allowsAny(c1, c4));
	assert( allowsAny(c1, c5));
	assert(!allowsAny(c1, c6));

	assert(!allowsAny(c2, c1));
	assert(!allowsAny(c2, c2));
	assert(!allowsAny(c2, c3));
	assert(!allowsAny(c2, c4));
	assert( allowsAny(c2, c5));
	assert(!allowsAny(c2, c6));

	assert(!allowsAny(c3, c1));
	assert(!allowsAny(c3, c2));
	assert( allowsAny(c3, c3));
	assert(!allowsAny(c3, c4));
	assert( allowsAny(c3, c5));
	assert(!allowsAny(c3, c6));

	assert(!allowsAny(c4, c1));
	assert(!allowsAny(c4, c2));
	assert(!allowsAny(c4, c3));
	assert(!allowsAny(c4, c4));
	assert( allowsAny(c4, c5));
	assert(!allowsAny(c4, c6));

	assert( allowsAny(c5, c1));
	assert( allowsAny(c5, c2));
	assert( allowsAny(c5, c3));
	assert( allowsAny(c5, c4));
	assert( allowsAny(c5, c5));
	assert(!allowsAny(c5, c6));

	assert(!allowsAny(c6, c1));
	assert(!allowsAny(c6, c2));
	assert(!allowsAny(c6, c3));
	assert(!allowsAny(c6, c4));
	assert(!allowsAny(c6, c5));
	assert(!allowsAny(c6, c6));
}

//
// allowsAll
//

unittest {
	assert( allowsAll(c1, c1));
	assert(!allowsAll(c1, c2));
	assert(!allowsAll(c1, c3));
	assert(!allowsAll(c1, c4));
	assert(!allowsAll(c1, c5));
	assert(!allowsAll(c1, c6));

	assert(!allowsAll(c2, c1));
	assert(!allowsAll(c2, c2));
	assert(!allowsAll(c2, c3));
	assert(!allowsAll(c2, c4));
	assert(!allowsAll(c2, c5));
	assert(!allowsAll(c2, c6));

	assert(!allowsAll(c3, c1));
	assert(!allowsAll(c3, c2));
	assert( allowsAll(c3, c3));
	assert(!allowsAll(c3, c4));
	assert(!allowsAll(c3, c5));
	assert(!allowsAll(c3, c6));

	assert(!allowsAll(c4, c1));
	assert(!allowsAll(c4, c2));
	assert(!allowsAll(c4, c3));
	assert(!allowsAll(c4, c4));
	assert(!allowsAll(c4, c5));
	assert(!allowsAll(c4, c6));

	assert( allowsAll(c5, c1));
	assert( allowsAll(c5, c2));
	assert( allowsAll(c5, c3));
	assert( allowsAll(c5, c4));
	assert( allowsAll(c5, c5));
	assert( allowsAll(c5, c6));

	assert(!allowsAll(c6, c1));
	assert(!allowsAll(c6, c2));
	assert(!allowsAll(c6, c3));
	assert(!allowsAll(c6, c4));
	assert(!allowsAll(c6, c5));
	assert(!allowsAll(c6, c6));
}

//
// relation
//

void testSet(const(Conf) a, const(Conf) b, SetRelation exp,
		int line = __LINE__)
{
	const(SetRelation) rslt = relation(a, b);
	enforce!AssertError(rslt == exp,
		format("\na: %s\nb: %s\nexp: %s\nrsl: %s", a, b, exp, rslt),
		__FILE__, line);
}

unittest {
	Conf nc1 = Conf("", IsPositive.yes);
	Conf nc2 = Conf("conf1", IsPositive.yes);
	Conf nc3 = Conf("conf1", IsPositive.no);
	Conf nc4 = Conf("conf2", IsPositive.yes);
	Conf nc5 = Conf("conf2", IsPositive.no);
	Conf nc6 = Conf("", IsPositive.no);

	testSet(nc1, nc1, SetRelation.subset);
	testSet(nc1, nc2, SetRelation.overlapping);
	testSet(nc1, nc3, SetRelation.overlapping);
	testSet(nc1, nc4, SetRelation.overlapping);
	testSet(nc1, nc5, SetRelation.overlapping);
	testSet(nc1, nc6, SetRelation.disjoint);
	testSet(nc2, nc1, SetRelation.subset);
	testSet(nc2, nc2, SetRelation.subset);
	testSet(nc2, nc3, SetRelation.disjoint);
	testSet(nc2, nc4, SetRelation.disjoint);
	testSet(nc2, nc5, SetRelation.disjoint);
	testSet(nc2, nc6, SetRelation.disjoint);
	testSet(nc3, nc1, SetRelation.subset);
	testSet(nc3, nc2, SetRelation.disjoint);
	testSet(nc3, nc3, SetRelation.disjoint);
	testSet(nc3, nc4, SetRelation.disjoint);
	testSet(nc3, nc5, SetRelation.disjoint);
	testSet(nc3, nc6, SetRelation.disjoint);
	testSet(nc4, nc1, SetRelation.subset);
	testSet(nc4, nc2, SetRelation.disjoint);
	testSet(nc4, nc3, SetRelation.disjoint);
	testSet(nc4, nc4, SetRelation.subset);
	testSet(nc4, nc5, SetRelation.disjoint);
	testSet(nc4, nc6, SetRelation.disjoint);
	testSet(nc5, nc1, SetRelation.subset);
	testSet(nc5, nc2, SetRelation.disjoint);
	testSet(nc5, nc3, SetRelation.disjoint);
	testSet(nc5, nc4, SetRelation.disjoint);
	testSet(nc5, nc5, SetRelation.disjoint);
	testSet(nc5, nc6, SetRelation.disjoint);
	testSet(nc6, nc1, SetRelation.subset);
	testSet(nc6, nc2, SetRelation.disjoint);
	testSet(nc6, nc3, SetRelation.disjoint);
	testSet(nc6, nc4, SetRelation.disjoint);
	testSet(nc6, nc5, SetRelation.disjoint);
	testSet(nc6, nc6, SetRelation.disjoint);
}

unittest {
	Conf[] tt;
	foreach(c1; ["", "conf", "conf2", "conf3"]) {
		foreach(c2; [IsPositive.no, IsPositive.yes]) {
			tt ~= Conf(c1, c2);
		}
	}

	foreach(it; tt) {
		foreach(jt; tt) {
			relation(it, jt);
		}
	}
}


