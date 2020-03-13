module dud.resolve.confstests;

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

const(Confs) c12 = Confs([c1, c2]);
const(Confs) c13 = Confs([c1, c3]);
const(Confs) c14 = Confs([c1, c4]);
const(Confs) c15 = Confs([c1, c5]);
const(Confs) c16 = Confs([c1, c6]);

const(Confs) c23 = Confs([c2, c3]);
const(Confs) c24 = Confs([c2, c4]);
const(Confs) c25 = Confs([c2, c5]);
const(Confs) c26 = Confs([c2, c6]);

const(Confs) c34 = Confs([c3, c4]);
const(Confs) c35 = Confs([c3, c5]);
const(Confs) c36 = Confs([c3, c6]);

const(Confs) c45 = Confs([c4, c5]);
const(Confs) c46 = Confs([c4, c6]);

const(Confs) c56 = Confs([c5, c6]);

const cs = [c12, c13, c14, c15, c16, c23, c24, c25, c26, c34, c35, c36, c45,
	 c46, c56];

// invert

unittest {
	void test(const(Confs) a, const(Confs) exp, int line = __LINE__) {
		const inv = a.invert();
		enforce!AssertError(inv == exp, format("\ninp: %s\nrsl: %s\nexp: %s", a,
				inv, exp), __FILE__, line);
	}

	test(c12, c12);
	test(c13, c24);
	test(c14, c23);
	test(c15, c25); // c5 is special
	test(c16, Confs.init); // c6 makes everything false

	test(c23, c14);
	test(c24, c13);
	test(c25, c15);
	test(c26, Confs.init);

	test(c34, c34);
	test(c35, c45);
	test(c36, Confs.init);

	test(c45, c35);
	test(c46, Confs.init);

	test(c56, Confs.init);
}

unittest {
	const c = Confs([c1]).invert();
	const e = Confs([c2]);
	assert(c == e, format("\n%s\n%s", c, e));
}

unittest {
	const nc12 = c12.invert();
	assert(nc12.confs.length == 2);
	assert(nc12.confs[0] == c2);
	assert(nc12.confs[1] == c1);
}

// differenceOf

unittest {
	const c11 = Confs([c1]);
	const c33 = Confs([c3]);
	const c13 = differenceOf(c11, c33);
	assert(c13.confs.length == 2);
	assert(c13.confs[0] == c4, format("%s", c13.confs[0]));
	assert(c13.confs[1] == c1, format("%s", c13.confs[1]));
}

unittest {
	foreach(it; cs) {
		foreach(jt; cs) {
			const r = differenceOf(it, jt);
			if(it == jt) {
				assert(!allowsAny(r, jt), format("%s", r));
				assert(!allowsAny(r, it), format("%s", r));
			}
		}
	}
}

// allowAll

unittest {
	void testAllowAll(const(Confs) a, const(Confs) b, const bool exp,
			int line = __LINE__)
	{
		struct Indivitual {
			@safe pure:
			const(Conf) a;
			const(Conf) b;

			string toString() const {
				return format("\ta: %s\tb: %s\t%s", a, b, allowsAll(a, b));
			}
		}

		const bool rslt = allowsAll(a, b);
		enforce!AssertError(rslt == exp,
			format("\na: %s\nb: %s\nexp: %s\nrsl: %s\nall:\n%(%s\n%)", a, b,
				exp,
				rslt,
				a.confs
					.map!(it => b.confs.map!(jt => Indivitual(it, jt)))
					.joiner),
			__FILE__, line);
	}

	foreach(it; cs) {
		foreach(jt; cs) {
			if(it != jt) {
				testAllowAll(it, jt, false);
			}
		}
	}
}

unittest {
	void testAllowAll(const(Confs) a, const(Conf) b, const bool exp,
			int line = __LINE__)
	{
		struct Indivitual {
			@safe pure:
			const(Conf) a;
			const(Conf) b;

			string toString() const {
				return format("\ta: %s\tb: %s\t%s", a, b, allowsAll(a, b));
			}
		}

		const bool rslt = allowsAll(a, b);
		enforce!AssertError(rslt == exp,
			format("\na: %s\nb: %s\nexp: %s\nrsl: %s\nall:\n%(%s\n%)", a, b, exp,
				rslt, a.confs.map!(it => Indivitual(it, b))),
			__FILE__, line);
	}

	testAllowAll(c12, c1, false);
	testAllowAll(c12, c2, false);
	testAllowAll(c12, c3, false);
	testAllowAll(c12, c4, false);
	testAllowAll(c12, c5, false);
	testAllowAll(c12, c6, false);

	testAllowAll(c13, c1, false);
	testAllowAll(c13, c2, false);
	testAllowAll(c13, c3, false);
	testAllowAll(c13, c4, false);
	testAllowAll(c13, c5, false);
	testAllowAll(c13, c6, false);

	testAllowAll(c24, c1, false);
	testAllowAll(c24, c2, false);
	testAllowAll(c24, c3, false);
	testAllowAll(c24, c4, false);
	testAllowAll(c24, c5, false);
	testAllowAll(c24, c6, false);

	const(Confs) c22 = Confs([c2, c2]);
	testAllowAll(c22, c2, true);
}
