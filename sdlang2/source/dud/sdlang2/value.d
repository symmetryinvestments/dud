module dud.sdlang2.value;

import std.datetime : DateTime, Duration, Date;

/// DateTime doesn't support milliseconds, but SDL's "Date Time" type does.
/// So this is needed for any SDL "Date Time" that doesn't include a time zone.
struct DateTimeFrac {
@safe pure:
	this(DateTime dt, Duration fs) {
		this.dateTime = dt;
		this.fracSecs = fs;
	}

	this(DateTime dt) {
		this.dateTime = dt;
	}

	DateTime dateTime;
	Duration fracSecs;
}

/++
If a "Date Time" literal in the SDL file has a time zone that's not found in
your system, you get one of these instead of a SysTime. (Because it's
impossible to indicate "unknown time zone" with 'std.datetime.TimeZone'.)

The difference between this and 'DateTimeFrac' is that 'DateTimeFrac'
indicates that no time zone was specified in the SDL at all, whereas
'DateTimeFracUnknownZone' indicates that a time zone was specified but
data for it could not be found on your system.
+/
struct DateTimeFracUnknownZone {
@safe pure:
	DateTime dateTime;
	Duration fracSecs;
	string timeZone;

	bool opEquals(const DateTimeFracUnknownZone b) const {
		return opEquals(b);
	}

	bool opEquals(ref const DateTimeFracUnknownZone b) const {
		return this.dateTime == b.dateTime && this.fracSecs  == b.fracSecs
			&& this.timeZone == b.timeZone;
	}
}

enum ValueType {
	boolean,
	int32,
	int64,
	float32,
	float64,
	float128,
	decimal128,
	date,
	datetime,
	datetimeTZ,
	duration,
	binary,
	str,
	char_,
	null_
}

private union Data {
	long interger;
	double floating64;
	real floating128;
	bool boolean;
	Duration duration;
	Date date;
	DateTimeFrac datetime;
	DateTimeFracUnknownZone datetimeUZ;
	ubyte[] binary;
	string str;
	dchar character;
}

struct Value {
@safe pure:
	ValueType type = ValueType.null_;
	Data data;

	this(Duration i) @trusted {
		this.type = ValueType.duration;
		this.data.duration = i;
	}

	this(dchar i) @trusted {
		this.type = ValueType.char_;
		this.data.character = i;
	}

	this(string i) @trusted {
		this.type = ValueType.str;
		this.data.str = i;
	}

	this(ubyte[] i) @trusted {
		this.type = ValueType.binary;
		this.data.binary = i;
	}

	this(DateTimeFracUnknownZone i) @trusted {
		this.type = ValueType.datetimeTZ;
		this.data.datetimeUZ = i;
	}

	this(DateTimeFrac i) @trusted {
		this.type = ValueType.datetime;
		this.data.datetime = i;
	}

	this(Date i) @trusted {
		this.type = ValueType.date;
		this.data.date = i;
	}

	this(bool i) @trusted {
		this.type = ValueType.boolean;
		this.data.boolean = i;
	}

	this(int i) @trusted {
		this.type = ValueType.int32;
		this.data.interger = i;
	}

	this(long i) @trusted {
		this.type = ValueType.int64;
		this.data.interger = i;
	}

	this(float i) @trusted {
		this.type = ValueType.float32;
		this.data.floating64 = i;
	}

	this(double i) @trusted {
		this.type = ValueType.float64;
		this.data.floating64 = i;
	}

	this(real i) @trusted {
		this.type = ValueType.float128;
		this.data.floating128 = i;
	}
}
