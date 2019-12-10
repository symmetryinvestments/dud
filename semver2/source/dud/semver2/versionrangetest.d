module dud.semver2.versionrangetest;

@safe pure private:
import std.format : format;
import dud.semver2.semver;
import dud.semver2.parse;
import dud.semver2.versionrange;

unittest {
	void test(const SemVer lowA, const Inclusive lowAIn, const SemVer highA,
			const Inclusive highAIn, const SemVer lowB, const Inclusive lowBIn,
			const SemVer highB, const Inclusive highBIn,
			const SetRelation br)
	{
		auto v1 = VersionRange(lowA, lowAIn, highA, highAIn);
		auto v2 = VersionRange(lowB, lowBIn, highB, highBIn);

		auto b = relation(v1, v2);
		assert(b == br, format(
			"\nexp: %s\ngot: %s\na: %s\nb: %s", br, b, v1, v2));
	}

	const i = Inclusive.yes;
	const o = Inclusive.no;

	auto a = parseSemVer("0.0.0");
	auto b = parseSemVer("1.0.0");
	auto c = parseSemVer("2.0.0");
	auto d = parseSemVer("3.0.0");
	auto e = parseSemVer("4.0.0");

	// a: [ . ] . . . . . . . .
	// b: . . . [ . . . ] . . .

	test(a, i, b, i, c, i, e, i, SetRelation.disjoint);

	// a: [ . ) . . . . . . . .
	// b: . . [ . . . . ] . . .
	test(a, i, b, o, b, i, e, i, SetRelation.disjoint);
	// a: . . . . . . . . [ . ]
	// b: . . . [ . . . ] . . .

	test(e, i, e, i, b, i, c, i, SetRelation.disjoint);

	// a: . . . . . . . . [ . ]
	// b: . . . [ . . . . ) . .
	test(d, i, e, i, b, i, d, o, SetRelation.disjoint);
	// a: . . . ( . . . . ) . .
	// b: . . . [ . . . . ] . .
	test(b, o, e, o, b, i, e, i, SetRelation.subset);

	// a: . . . [ . . . . ) . .
	// b: . . . [ . . . . ] . .
	test(b, i, e, o, b, i, e, i, SetRelation.subset);

	// a: . . . [ . . . . ] . .
	// b: . . . [ . . . . ] . .
	test(b, i, e, i, b, i, e, i, SetRelation.subset);

	// a: . . . ( . . . . ] . .
	// b: . . . [ . . . . ] . .
	test(b, o, e, i, b, i, e, i, SetRelation.subset);

	// a: . . . ( . . . . ] . .
	// b: . . . ( . . . . ] . .
	test(b, o, e, i, b, o, e, i, SetRelation.subset);

	// a: . . . ( . . . . ) . .
	// b: . . . ( . . . . ) . .
	test(b, o, e, o, b, o, e, o, SetRelation.subset);

	// a: . . . . | . . . | . .
	// b: . . . | . . . . | . .
	test(c, o, e, o, b, o, e, o, SetRelation.subset);

	// a: . . . . | . . | . . .
	// b: . . . | . . . . | . .
	test(c, o, d, o, b, o, e, o, SetRelation.subset);

	// a: . . . | . . . | . . .
	// b: . . . | . . . . | . .
	test(b, o, d, o, b, o, e, o, SetRelation.subset);
	test(b, o, d, o, b, i, e, i, SetRelation.subset);

	// a: [ . ] . . . . . . . .
	// b: . . [ . . . . ] . . .
	test(a, i, b, i, b, i, e, i, SetRelation.overlapping);

	// a: . . . . . . . . [ . ]
	// b: . . . [ . . . . ] . .
	test(d, i, e, i, b, i, d, i, SetRelation.overlapping);

	// a: . . . . . . . | . . |
	// b: . . . [ . . . . ] . .
	test(c, i, e, i, b, i, d, i, SetRelation.overlapping);

	// a: . | . . . . . | . . .
	// b: . . . [ . . . . ] . .
	test(a, i, c, i, b, i, d, i, SetRelation.overlapping);

	// a: . | . . . . . . | . .
	// b: . . . | . . . . | . .
	test(a, i, d, i, b, i, d, i, SetRelation.overlapping);

	// a: . . . | . . . . . | .
	// b: . . . | . . . . | . .
	test(b, i, e, i, b, i, d, i, SetRelation.overlapping);

	// a: . . [ . . . . . . ] .
	// b: . . . [ . . . . ] . .
	test(a, i, e, i, b, i, d, i, SetRelation.overlapping);

	// a: . . . [ . . . . ] . .
	// b: . . . [ . . . . ) . .
	test(b, i, c, i, b, i, c, o, SetRelation.overlapping);

	// a: . . . [ . . . . ] . .
	// b: . . . ( . . . . ] . .
	test(b, i, c, i, b, o, c, i, SetRelation.overlapping);

	// a: . . . [ . . . . ] . .
	// b: . . . ( . . . . ) . .
	test(b, i, c, i, b, o, c, i, SetRelation.overlapping);

	// a: . . . ( . . . . ] . .
	// b: . . . [ . . . . ) . .
	test(b, i, c, o, b, o, c, i, SetRelation.overlapping);

	// a: . . . [ . . . . ] . .
	// b: . . . ( . . . . ) . .
	test(b, i, c, i, b, o, c, o, SetRelation.overlapping);

	// a: . . . [ . . . . ) . .
	// b: . . . ( . . . . ) . .
	test(b, i, c, o, b, o, c, o, SetRelation.overlapping);

	// a: . . . [ . . . . ] . .
	// b: . . . ( . . . ] . . .
	test(b, i, d, i, b, o, c, i, SetRelation.overlapping);

	// a: . . . [ . . . . ) . .
	// b: . . . . ( . . . ] . .
	test(b, i, d, o, c, i, d, i, SetRelation.overlapping);

	// a: . . . ( . . . . ] . .
	// b: . . . [ . . . . ) . .
	test(b, o, d, i, b, i, d, o, SetRelation.overlapping);
}

unittest {
	auto a = parseSemVer("0.0.0");
	auto b = parseSemVer("1.0.0");
	auto c = parseSemVer("2.0.0");

	auto v1 = VersionRange(b, Inclusive.yes, c, Inclusive.no);
	auto v2 = VersionRange(a, Inclusive.yes, b, Inclusive.no);

	SetRelation sr = relation(v1, v2);
	assert(sr == SetRelation.disjoint, format("%s", sr));
}

unittest {
	SemVer[] sv =
		[ parseSemVer("1.0.0"), parseSemVer("2.0.0"), parseSemVer("3.0.0")
		, parseSemVer("4.0.0"), parseSemVer("5.0.0")
		];

	Inclusive[] inclusive  = [Inclusive.yes, Inclusive.no];

	VersionRange[] vers;
	foreach(idx, low; sv[0 .. $ - 1]) {
		foreach(lowIn; inclusive) {
			foreach(high; sv[idx + 1 .. $]) {
				foreach(highIn; inclusive) {
					VersionRange tmp;
					tmp.inclusiveLow = lowIn;
					tmp.low = low;
					tmp.inclusiveHigh = highIn;
					tmp.high = high;
					vers ~= tmp;
				}
			}
		}
	}

	//debug writefln("%(%s\n%)", vers);
	foreach(adx, verA; vers) {
		foreach(bdx, verB; vers) {
			assert(!verA.isBranch());
			assert(!verB.isBranch());
			auto rel = relation(verA, verB);
			//writefln("a: %s, b: %s, rel %s", verA, verB, rel);
			auto reporter = () {
				return format("\na: %s, b: %s, rel %s", verA, verB, rel);
			};
			if(adx == bdx) {
				assert(rel == SetRelation.subset, reporter());
			} else if(verA.high < verB.low) {
				assert(rel == SetRelation.disjoint, reporter());
			} else if(verA.low > verB.high) {
				assert(rel == SetRelation.disjoint, reporter());
			} else if(verA.low < verB.low && verA.high > verB.high) {
				assert(rel == SetRelation.overlapping, reporter());
			} else if(verA.low > verB.low && verA.high < verB.high) {
				assert(rel == SetRelation.subset, reporter());
			} else {
				assert((rel == SetRelation.overlapping)
						|| (rel == SetRelation.subset)
						|| (rel == SetRelation.disjoint), reporter());
			}
		}
	}
}

unittest {
	SemVer a = parseSemVer("1.0.0");
	SemVer b = parseSemVer("2.0.0");
	SemVer c = parseSemVer("3.0.0");

	auto v1 = VersionRange(a, Inclusive.no, b, Inclusive.yes);
	auto v2 = VersionRange(b, Inclusive.yes, c, Inclusive.yes);
	assert(!v1.isBranch());
	assert(!v2.isBranch());

	auto rel = relation(v1, v2);
	assert(rel == SetRelation.overlapping, format("%s", rel));
}

unittest {
	SemVer a = parseSemVer("1.0.0");
	SemVer b = parseSemVer("2.0.0");
	SemVer c = parseSemVer("3.0.0");
	SemVer d = parseSemVer("99999.0.0");

	auto v1 = VersionRange(a, Inclusive.no, b, Inclusive.no);
	assert(!v1.isBranch());
	auto v2 = VersionRange(b, Inclusive.no, c, Inclusive.yes);
	assert(!v2.isBranch());
	auto v3 = VersionRange(b, Inclusive.yes, c, Inclusive.yes);
	assert(!v3.isBranch());
	auto v4 = VersionRange(a, Inclusive.no, b, Inclusive.yes);
	assert(!v4.isBranch());
	auto v5 = VersionRange(b, Inclusive.yes, c, Inclusive.yes);
	assert(!v5.isBranch());
	auto v6 = VersionRange(c, Inclusive.no, d, Inclusive.yes);
	assert(!v6.isBranch());

	auto rel = relation(v1, v2);
	assert(rel == SetRelation.disjoint, format("%s", rel));

	rel = relation(v1, v3);
	assert(rel == SetRelation.disjoint, format("%s", rel));

	rel = relation(v3, v4);
	assert(rel == SetRelation.overlapping, format("%s", rel));

	rel = relation(v5, v6);
	assert(rel == SetRelation.disjoint, format("%s", rel));
}
