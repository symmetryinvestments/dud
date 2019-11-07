module dud.pkgdescription.outpututils;

@safe pure:

private enum string[dchar] tTable = [
	'"' : "\\\"", '\n' : "\\\\n", '\v' : "\\\v", '\r' : "\\\r", '\\' : "\\\\"
];

string escapeString(string s) {
	import std.array : appender;
	import std.conv : to;
	import std.string : translate;
	auto app = appender!(dchar[])();
	translate(s, tTable, null, app);
	return to!string(app.data);
}

unittest {
	string s = "Hello \"World";
	string se = s.escapeString();
	assert(se == "Hello \\\"World", se);
}

bool containsEscapable(string s) {
	foreach(idx; 0 .. s.length) {
		if(s[idx] == '\n'
				|| s[idx] == '"'
				|| s[idx] == '\r'
				|| s[idx] == '\\')
		{
			return true;
		}
	}
	return false;
}
