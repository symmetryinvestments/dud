// SDLang-D
// Written in the D programming language.

module dud.sdlang.token;

import std.array;
import std.base64;
import std.conv;
import std.datetime;
import std.range;
import std.string;
import std.meta : AliasSeq;
import std.variant;

import dud.sdlang.symbol;
import dud.sdlang.util;

/// DateTime doesn't support milliseconds, but SDL's "Date Time" type does.
/// So this is needed for any SDL "Date Time" that doesn't include a time zone.
struct DateTimeFrac
{
	@safe pure:
	this(DateTime dt, Duration fs) { this.dateTime = dt; this.fracSecs = fs; }
	this(DateTime dt) { this.dateTime = dt; }

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
struct DateTimeFracUnknownZone
{
	@safe pure:
	DateTime dateTime;
	Duration fracSecs;
	string timeZone;

	bool opEquals(const DateTimeFracUnknownZone b) const
	{
		return opEquals(b);
	}
	bool opEquals(ref const DateTimeFracUnknownZone b) const
	{
		return
			this.dateTime == b.dateTime &&
			this.fracSecs  == b.fracSecs  &&
			this.timeZone == b.timeZone;
	}
}

/++
SDL's datatypes map to D's datatypes as described below.
Most are straightforward, but take special note of the date/time-related types.

Boolean:                       bool
Null:                          typeof(null)
Unicode Character:             dchar
Double-Quote Unicode String:   string
Raw Backtick Unicode String:   string
Integer (32 bits signed):      int
Long Integer (64 bits signed): long
Float (32 bits signed):        float
Double Float (64 bits signed): double
Decimal (128+ bits signed):    real
Binary (standard Base64):      ubyte[]
Time Span:                     Duration

Date (with no time at all):           Date
Date Time (no timezone):              DateTimeFrac
Date Time (with a known timezone):    SysTime
Date Time (with an unknown timezone): DateTimeFracUnknownZone
+/
alias AliasSeq!(
	bool,
	string, dchar,
	int, long,
	float, double, real,
	Date, DateTimeFrac, SysTime, DateTimeFracUnknownZone, Duration,
	ubyte[],
	typeof(null),
) ValueTypes;

alias Algebraic!( ValueTypes ) Value; ///ditto

template isSDLSink(T)
{
	enum isSink =
		isOutputRange!T &&
		is(ElementType!(T)[] == string);
}

string toSDLString(T)(T value) @trusted pure if(
	is( T : Value        ) ||
	is( T : bool         ) ||
	is( T : string       ) ||
	is( T : dchar        ) ||
	is( T : int          ) ||
	is( T : long         ) ||
	is( T : float        ) ||
	is( T : double       ) ||
	is( T : real         ) ||
	is( T : Date         ) ||
	is( T : DateTimeFrac ) ||
	is( T : SysTime      ) ||
	is( T : DateTimeFracUnknownZone ) ||
	is( T : Duration     ) ||
	is( T : ubyte[]      ) ||
	is( T : typeof(null) ))
{
	alias App = Appender!string;
	App sink;
	toSDLStringImpl!(App).toSDLString(value, sink);
	return sink.data;
}

private T pureSafeGet(T)(Value value) @trusted {
	return value.get!T();
}

private string valueToString(Value value) @trusted {
	return value.toString();
}

template toSDLStringImpl(Sink) if(isOutputRange!(Sink,char)) {

	pure void toSDLString(Value value, ref Sink sink) {
		bool cmp(Value a, TypeInfo b) @trusted {
			return a.type == b;
		}

		auto dl = assumePure(&cmp);

		static foreach(T; ValueTypes) {
			if(dl(value, typeid(T))) {
				auto g = assumePure(&pureSafeGet!T);
				T v = g(value);
				toSDLString(v, sink);
				return;
			}
		}

		auto ts = assumePure(&valueToString);

		throw new Exception(
			"Internal SDLang-D error: Unhandled type of Value. Contains: "
			~ ts(value));
	}

	void toSDLString(typeof(null) value, ref Sink sink) pure {
		auto d = assumePure(&toSDLStringNullImpl);
		d(value, sink);
	}

	void toSDLStringNullImpl(typeof(null) value, ref Sink sink) {
		sink.put("null");
	}

	void toSDLString(bool value, ref Sink sink) pure {
		auto d = assumePure(&toSDLStringBoolImpl);
		d(value, sink);
	}

	void toSDLStringBoolImpl(bool value, ref Sink sink) {
		sink.put(value? "true" : "false");
	}

	void toSDLString(string value, ref Sink sink) pure {
		auto d = assumePure(&toSDLStringStrImpl);
		d(value, sink);
	}

	//TODO: Figure out how to properly handle strings/chars containing lineSep or paraSep
	void toSDLStringStrImpl(string value, ref Sink sink) {
		sink.put('"');

		// This loop is UTF-safe
		foreach(char ch; value)
		{
			if     (ch == '\n') sink.put(`\n`);
			else if(ch == '\r') sink.put(`\r`);
			else if(ch == '\t') sink.put(`\t`);
			else if(ch == '\"') sink.put(`\"`);
			else if(ch == '\\') sink.put(`\\`);
			else
				sink.put(ch);
		}

		sink.put('"');
	}

	void toSDLString(dchar value, ref Sink sink) pure {
		auto d = assumePure(&toSDLStringDcharImpl);
		d(value, sink);
	}

	void toSDLStringDcharImpl(dchar value, ref Sink sink) {
		sink.put('\'');

		if     (value == '\n') sink.put(`\n`);
		else if(value == '\r') sink.put(`\r`);
		else if(value == '\t') sink.put(`\t`);
		else if(value == '\'') sink.put(`\'`);
		else if(value == '\\') sink.put(`\\`);
		else
			sink.put(value);

		sink.put('\'');
	}
	void toSDLString(int value, ref Sink sink) pure {
		auto d = assumePure(&toSDLStringIntImpl);
		d(value, sink);
	}

	void toSDLStringIntImpl(int value, ref Sink sink) {
		sink.put( "%s".format(value) );
	}

	void toSDLString(long value, ref Sink sink) pure {
		auto d = assumePure(&toSDLStringLongImpl);
		d(value, sink);
	}

	void toSDLStringLongImpl(long value, ref Sink sink) {
		sink.put( "%sL".format(value) );
	}

	void toSDLString(float value, ref Sink sink) pure {
		string ts() {
			return format("%.10sF", value);
		}

		auto dl = assumePure(&ts);
		sink.put( dl() );
	}

	void toSDLString(double value, ref Sink sink) pure {
		string ts() {
			return format("%.30sD", value);
		}

		auto dl = assumePure(&ts);
		sink.put( dl() );
	}

	void toSDLString(real value, ref Sink sink) pure {
		string ts() {
			return format("%.30sBD", value);
		}

		auto dl = assumePure(&ts);
		sink.put( dl() );
	}

	void toSDLString(Date value, ref Sink sink) pure {
		sink.put(to!string(value.year));
		sink.put('/');
		sink.put(to!string(cast(int)value.month));
		sink.put('/');
		sink.put(to!string(value.day));
	}

	void toSDLString(DateTimeFrac value, ref Sink sink) pure {
		toSDLString(value.dateTime.date, sink);
		sink.put(' ');
		sink.put("%.2s".format(value.dateTime.hour));
		sink.put(':');
		sink.put("%.2s".format(value.dateTime.minute));

		if(value.dateTime.second != 0)
		{
			sink.put(':');
			sink.put("%.2s".format(value.dateTime.second));
		}

		if(value.fracSecs.total!"msecs" != 0)
		{
			sink.put('.');
			sink.put("%.3s".format(value.fracSecs.total!"msecs"));
		}
	}

	private string timezoneToStr(immutable(TimeZone) tz, long stdTime) @safe {
		return tz.dstInEffect(stdTime)? tz.dstName : tz.stdName;
	}

	private string timezoneStdName(immutable(TimeZone) tz) {
		return tz.stdName;
	}

	private string timezoneName(immutable(TimeZone) tz) {
		return tz.name;
	}

	private DateTimeFrac valueToDT(SysTime v) {
		return DateTimeFrac(cast(DateTime)v, v.fracSecs);
	}

	private bool timezoneHasDST(immutable(TimeZone) tz) {
		return tz.hasDST();
	}

	void toSDLString(SysTime value, ref Sink sink) pure {
		auto dl = assumePure(&toSDLStringSysTimeImpl);
		dl(value, sink);
	}

	void toSDLStringSysTimeImpl(SysTime value, ref Sink sink) {
		auto dtf = assumePure(&valueToDT);
		auto dateTimeFrac = dtf(value);
		toSDLString(dateTimeFrac, sink);

		sink.put("-");

		auto ldl = assumePure(&timezoneName);
		auto tzString = ldl(value.timezone);

		// If name didn't exist, try abbreviation.
		// Note that according to std.datetime docs, on Windows the
		// stdName/dstName may not be properly abbreviated.
		version(Windows) {} else
		if(tzString == "")
		{
			immutable(TimeZone) tz = value.timezone;
			long stdTime = value.stdTime;

			auto dst = assumePure(&timezoneHasDST);

			if(dst(tz)) {
				auto dl = assumePure(&timezoneToStr);
				tzString = dl(tz, stdTime);
			} else {
				auto dl = assumePure(&timezoneStdName);
				tzString = dl(tz);
			}
		}

		if(tzString == "")
		{
			auto offset = value.timezone.utcOffsetAt(value.stdTime);
			sink.put("GMT");

			if(offset < seconds(0))
			{
				sink.put("-");
				offset = -offset;
			}
			else
				sink.put("+");

			long hours, minutes;
			offset.split!("hours", "minutes")(hours, minutes);

			sink.put("%.2s".format(hours));
			sink.put(":");
			sink.put("%.2s".format(minutes));
		}
		else
			sink.put(tzString);
	}

	void toSDLString(DateTimeFracUnknownZone value, ref Sink sink) pure {
		auto dl = assumePure(&toSDLStringDTFUZimpl);
		dl(value, sink);
	}

	void toSDLStringDTFUZimpl(DateTimeFracUnknownZone value, ref Sink sink) {
		auto dateTimeFrac = DateTimeFrac(value.dateTime, value.fracSecs);
		toSDLString(dateTimeFrac, sink);

		sink.put("-");
		sink.put(value.timeZone);
	}

	void toSDLString(Duration value, ref Sink sink) pure {
		auto dl = assumePure(&toSDLStringDurationImpl);
		dl(value, sink);
	}

	void toSDLStringDurationImpl(Duration value, ref Sink sink) {
		if(value < seconds(0))
		{
			sink.put("-");
			value = -value;
		}

		auto s = value.split();

		auto days = value.total!"days"();
		if(days != 0)
		{
			sink.put("%s".format(days));
			sink.put("d:");
		}

		long hours = s.hours;
		long minutes = s.minutes;
		long seconds = s.seconds;
		long msecs = s.msecs;
		//	, minutes, seconds, msecs;
		//value.split!("hours", "minutes", "seconds", "msecs")(hours, minutes, seconds, msecs);

		sink.put("%.2s".format(hours));
		sink.put(':');
		sink.put("%.2s".format(minutes));
		sink.put(':');
		sink.put("%.2s".format(seconds));

		if(msecs != 0)
		{
			sink.put('.');
			sink.put("%.3s".format(msecs));
		}
	}

	void toSDLString(ubyte[] value, ref Sink sink) pure {
		auto dl = assumePure(&toSDLStringUbyteImpl);
		dl(value, sink);
	}

	void toSDLStringUbyteImpl(ubyte[] value, ref Sink sink) {
		sink.put('[');
		sink.put( Base64.encode(value) );
		sink.put(']');
	}

}


/// This only represents terminals. Nonterminals aren't
/// constructed since the AST is directly built during parsing.
struct Token
{
	@safe:
	Symbol symbol = dud.sdlang.symbol.symbol!"Error"; /// The "type" of this token
	Location location;
	Value value; /// Only valid when 'symbol' is symbol!"Value", otherwise null
	string data; /// Original text from source

	@disable this();
	this(Symbol symbol, Location location, Value value=Value(null),
			string data=null) pure
	{
		this.symbol   = symbol;
		this.location = location;
		this.value    = value;
		this.data     = data;
	}

	/// Tokens with differing symbols are always unequal.
	/// Tokens with differing values are always unequal.
	/// Tokens with differing Value types are always unequal.
	/// Member 'location' is always ignored for comparison.
	/// Member 'data' is ignored for comparison *EXCEPT* when the symbol is Ident.
	bool opEquals(Token b) pure
	{
		return opEquals(b);
	}

	bool opEquals(ref Token b) pure @trusted {
		auto dl = assumePure(&opEqualsImpl);
		return dl(b);
	}

	bool opEqualsImpl(ref Token b) @trusted {
		if(
			this.symbol     != b.symbol     ||
			this.value.type != b.value.type ||
			this.value      != b.value
		)
			return false;

		if(this.symbol == .symbol!"Ident")
			return this.data == b.data;

		return true;
	}

	void opAssign(Token other) @safe pure {
		this.symbol = other;
		this.value = other.value;
		this.location = other.location;
		this.data = other.data;
	}

	bool matches(string symbolName)()
	{
		return this.symbol == .symbol!symbolName;
	}
}

@system pure unittest
{
	import std.stdio;

	auto loc  = Location("", 0, 0, 0);
	auto loc2 = Location("a", 1, 1, 1);

	assert(Token(symbol!"EOL",loc) == Token(symbol!"EOL",loc ));
	assert(Token(symbol!"EOL",loc) == Token(symbol!"EOL",loc2));
	assert(Token(symbol!":",  loc) == Token(symbol!":",  loc ));
	assert(Token(symbol!"EOL",loc) != Token(symbol!":",  loc ));
	assert(Token(symbol!"EOL",loc,Value(null),"\n") == Token(symbol!"EOL",loc,Value(null),"\n"));

	assert(Token(symbol!"EOL",loc,Value(null),"\n") == Token(symbol!"EOL",loc,Value(null),";" ));
	assert(Token(symbol!"EOL",loc,Value(null),"A" ) == Token(symbol!"EOL",loc,Value(null),"B" ));
	assert(Token(symbol!":",  loc,Value(null),"A" ) == Token(symbol!":",  loc,Value(null),"BB"));
	assert(Token(symbol!"EOL",loc,Value(null),"A" ) != Token(symbol!":",  loc,Value(null),"A" ));

	assert(Token(symbol!"Ident",loc,Value(null),"foo") == Token(symbol!"Ident",loc,Value(null),"foo"));
	assert(Token(symbol!"Ident",loc,Value(null),"foo") != Token(symbol!"Ident",loc,Value(null),"BAR"));

	assert(Token(symbol!"Value",loc,Value(null),"foo") == Token(symbol!"Value",loc, Value(null),"foo"));
	assert(Token(symbol!"Value",loc,Value(null),"foo") == Token(symbol!"Value",loc2,Value(null),"foo"));
	assert(Token(symbol!"Value",loc,Value(null),"foo") == Token(symbol!"Value",loc, Value(null),"BAR"));
	assert(Token(symbol!"Value",loc,Value(   7),"foo") == Token(symbol!"Value",loc, Value(   7),"BAR"));
	assert(Token(symbol!"Value",loc,Value(   7),"foo") != Token(symbol!"Value",loc, Value( "A"),"foo"));
	assert(Token(symbol!"Value",loc,Value(   7),"foo") != Token(symbol!"Value",loc, Value(   2),"foo"));
	assert(Token(symbol!"Value",loc,Value(cast(int)7)) != Token(symbol!"Value",loc, Value(cast(long)7)));
	assert(Token(symbol!"Value",loc,Value(cast(float)1.2)) != Token(symbol!"Value",loc, Value(cast(double)1.2)));
}

@system pure unittest
{
	import std.stdio;

	// Bool and null
	strAssert(Value(null ).toSDLString(), "null");
	strAssert(Value(true ).toSDLString(), "true");
	strAssert(Value(false).toSDLString(), "false");

	// Base64 Binary
	strAssert(Value(cast(ubyte[])"hello world".dup).toSDLString(), "[aGVsbG8gd29ybGQ=]");
}

@system pure unittest {
	// Integer
	strAssert(Value(cast( int) 7).toSDLString(),  "7");
	strAssert(Value(cast( int)-7).toSDLString(), "-7");
	strAssert(Value(cast( int) 0).toSDLString(),  "0");

	strAssert(Value(cast(long) 7).toSDLString(),  "7L");
	strAssert(Value(cast(long)-7).toSDLString(), "-7L");
	strAssert(Value(cast(long) 0).toSDLString(),  "0L");

	// Floating point
	strAssert(Value(cast(float) 1.5).toSDLString(),  "1.5F");
	strAssert(Value(cast(float)-1.5).toSDLString(), "-1.5F");
	strAssert(Value(cast(float)   0).toSDLString(),    "0F");

	strAssert(Value(cast(double) 1.5).toSDLString(),  "1.5D");
	strAssert(Value(cast(double)-1.5).toSDLString(), "-1.5D");
	strAssert(Value(cast(double)   0).toSDLString(),    "0D");

	strAssert(Value(cast(real) 1.5).toSDLString(),  "1.5BD");
	strAssert(Value(cast(real)-1.5).toSDLString(), "-1.5BD");
	strAssert(Value(cast(real)   0).toSDLString(),    "0BD");
}

unittest {
	// String
	strAssert(Value("hello"  ).toSDLString(), `"hello"`);
	strAssert(Value(" hello ").toSDLString(), `" hello "`);
	strAssert(Value(""       ).toSDLString(), `""`);
	strAssert(Value("hello \r\n\t\"\\ world").toSDLString(), `"hello \r\n\t\"\\ world"`);
	strAssert(Value("日本語").toSDLString(), `"日本語"`);

	// Chars
	strAssert(Value(cast(dchar) 'A').toSDLString(),  `'A'`);
	strAssert(Value(cast(dchar)'\r').toSDLString(), `'\r'`);
	strAssert(Value(cast(dchar)'\n').toSDLString(), `'\n'`);
	strAssert(Value(cast(dchar)'\t').toSDLString(), `'\t'`);
	strAssert(Value(cast(dchar)'\'').toSDLString(), `'\''`);
	strAssert(Value(cast(dchar)'\\').toSDLString(), `'\\'`);
	strAssert(Value(cast(dchar) '月').toSDLString(),  `'月'`);
}

unittest {
	// Date
	strAssert(Value(Date( 2004,10,31)).toSDLString(), "2004/10/31");
	strAssert(Value(Date(-2004,10,31)).toSDLString(), "-2004/10/31");

	// DateTimeFrac w/o Frac
	strAssert(Value(DateTimeFrac(DateTime(2004,10,31, 14,30,15))).toSDLString(), "2004/10/31 14:30:15");
	strAssert(Value(DateTimeFrac(DateTime(2004,10,31,   1, 2, 3))).toSDLString(), "2004/10/31 01:02:03");
	strAssert(Value(DateTimeFrac(DateTime(-2004,10,31, 14,30,15))).toSDLString(), "-2004/10/31 14:30:15");

	// DateTimeFrac w/ Frac
	strAssert(Value(DateTimeFrac(DateTime(2004,10,31,  14,30,15), 123.msecs)).toSDLString(),
		"2004/10/31 14:30:15.123");
	strAssert(Value(DateTimeFrac(DateTime(2004,10,31,  14,30,15), 120.msecs)).toSDLString(),
		"2004/10/31 14:30:15.120");
	strAssert(Value(DateTimeFrac(DateTime(2004,10,31,  14,30,15), 100.msecs)).toSDLString(),
		"2004/10/31 14:30:15.100");
	strAssert(Value(DateTimeFrac(DateTime(2004,10,31,  14,30,15), 12.msecs)).toSDLString(),
		"2004/10/31 14:30:15.012");
	strAssert(Value(DateTimeFrac(DateTime(2004,10,31,  14,30,15), 1.msecs)).toSDLString(),
		"2004/10/31 14:30:15.001");
	strAssert(Value(DateTimeFrac(DateTime(-2004,10,31, 14,30,15), 123.msecs)).toSDLString(),
		"-2004/10/31 14:30:15.123");

	// DateTimeFracUnknownZone
	strAssert(Value(DateTimeFracUnknownZone(DateTime(2004,10,31, 14,30,15), 123.msecs, "Foo/Bar")).toSDLString(), "2004/10/31 14:30:15.123-Foo/Bar");

}

unittest {
	// SysTime
	strAssert(Value(SysTime(DateTime(2004,10,31, 14,30,15), new immutable SimpleTimeZone( hours(0)             ))).toSDLString(),
		"2004/10/31 14:30:15-GMT+00:00");
	strAssert(Value(SysTime(DateTime(2004,10,31,  1, 2, 3), new immutable SimpleTimeZone( hours(0)             ))).toSDLString(),
		"2004/10/31 01:02:03-GMT+00:00");
	strAssert(Value(SysTime(DateTime(2004,10,31, 14,30,15), new immutable SimpleTimeZone( hours(2)+minutes(10) ))).toSDLString(),
		"2004/10/31 14:30:15-GMT+02:10");
	strAssert(Value(SysTime(DateTime(2004,10,31, 14,30,15), new immutable SimpleTimeZone(-hours(5)-minutes(30) ))).toSDLString(),
		"2004/10/31 14:30:15-GMT-05:30");
	strAssert(Value(SysTime(DateTime(2004,10,31, 14,30,15), new immutable SimpleTimeZone( hours(2)+minutes( 3) ))).toSDLString(),
		"2004/10/31 14:30:15-GMT+02:03");
	strAssert(Value(SysTime(DateTime(2004,10,31, 14,30,15), 123.msecs, new immutable SimpleTimeZone( hours(0) ))).toSDLString(),
		"2004/10/31 14:30:15.123-GMT+00:00");
}

unittest {
	// Duration
	strAssert(Value( days( 0)+hours(12)+minutes(14)+seconds(42)+msecs(  0)).toSDLString(),  "12:14:42"        );
	strAssert(Value(-days( 0)-hours(12)-minutes(14)-seconds(42)-msecs(  0)).toSDLString(), "-12:14:42"        );
	strAssert(Value( days( 0)+hours( 0)+minutes( 9)+seconds(12)+msecs(  0)).toSDLString(),  "00:09:12"        );
	strAssert(Value( days( 0)+hours( 0)+minutes( 0)+seconds( 1)+msecs( 23)).toSDLString(),  "00:00:01.023"    );
	strAssert(Value( days(23)+hours( 5)+minutes(21)+seconds(23)+msecs(  0)).toSDLString(),  "23d:05:21:23"    );
	strAssert(Value( days(23)+hours( 5)+minutes(21)+seconds(23)+msecs(532)).toSDLString(),  "23d:05:21:23.532");
	strAssert(Value( days(23)+hours( 5)+minutes(21)+seconds(23)+msecs(530)).toSDLString(),  "23d:05:21:23.530");
	strAssert(Value( days(23)+hours( 5)+minutes(21)+seconds(23)+msecs(500)).toSDLString(),  "23d:05:21:23.500");
	strAssert(Value(-days(23)-hours( 5)-minutes(21)-seconds(23)-msecs(532)).toSDLString(), "-23d:05:21:23.532");
	strAssert(Value(-days(23)-hours( 5)-minutes(21)-seconds(23)-msecs(500)).toSDLString(), "-23d:05:21:23.500");
}
