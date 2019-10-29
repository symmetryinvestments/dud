module dud.sdlang.parsertest;

import std.range : walkLength;
import std.stdio;

import dud.sdlang.lexer;
import dud.sdlang.parser;
import dud.sdlang.ast;
import dud.sdlang.astaccess;
import dud.sdlang.value;

@safe pure:

unittest {
	auto l = Lexer(`key "value"`);
	auto p = Parser(l);
	Root r = p.parseRoot();

	foreach(tag; tags(r)) {
		assert(tag.identifier() == "key", tag.identifier());
		auto vals = tag.values();
		assert(!vals.empty);
		assert(vals.front.type == ValueType.str);
	}
}

unittest {
	auto l = Lexer(`key "value"
			key2 1337`);
	auto p = Parser(l);
	Root r = p.parseRoot();

	auto vals = tags(r);

	assert(!vals.empty);
	auto f = vals.front;
	assert(f.identifier() == "key", f.identifier());
	auto val = f.values();
	assert(!val.empty);
	assert(val.front.type == ValueType.str);
	vals.popFront();

	assert(!vals.empty);
	f = vals.front;
	assert(f.identifier() == "key2", f.identifier());
	val = f.values();
	assert(!val.empty);
	assert(val.front.type == ValueType.int32);
	vals.popFront();

	assert(vals.empty);
}

unittest {
	auto l = Lexer(`
			key "value"
			key2 1337`);
	auto p = Parser(l);
	Root r = p.parseRoot();

	auto vals = tags(r);

	assert(!vals.empty);
	auto f = vals.front;
	assert(f.identifier() == "key", f.identifier());
	auto val = f.values();
	assert(!val.empty);
	assert(val.front.type == ValueType.str);
	vals.popFront();

	assert(!vals.empty);
	f = vals.front;
	assert(f.identifier() == "key2", f.identifier());
	val = f.values();
	assert(!val.empty);
	assert(val.front.type == ValueType.int32);
	vals.popFront();

	assert(vals.empty);
}

unittest {
	auto l = Lexer(`

			key      "value"

			key2 1337`);
	auto p = Parser(l);
	Root r = p.parseRoot();

	auto vals = tags(r);

	assert(!vals.empty);
	auto f = vals.front;
	assert(f.identifier() == "key", f.identifier());
	auto val = f.values();
	assert(!val.empty);
	assert(val.front.type == ValueType.str);
	vals.popFront();

	assert(!vals.empty);
	f = vals.front;
	assert(f.identifier() == "key2", f.identifier());
	val = f.values();
	assert(!val.empty);
	assert(val.front.type == ValueType.int32);
	vals.popFront();

	assert(vals.empty);
}

unittest {
	auto l = Lexer(`
			-- some lua style comment
// a c++ comment
someKEy "value" attr=1337 {
	a_nested_child "\"foobar" {
		and_a$depper_nesting:foo 123.3 ; args null
	}
}`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
someKEy {
	and_a$depper_nesting:foo 123.3 ; args null
}`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
			matrix
		`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
			matrix 1 12 32 323 1
	`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
			matrix 1 12 32 323 1 foo="bar" foo2="bar2"
	`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
			matrix {
				1 12 32
				2 22 42
				3 32 52
			}
	`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
// C++ style

/*
C style multiline
*/

tag /*foo=true*/ bar=false

# Shell style

-- Lua style
	`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
// Trailing semicolons are optional
title "Some title";

// They can be used to separate multiple nodes
title "Some title"; author "Peter Parker"

// Tags may contain certain non-alphanumeric characters
this-is_a.valid$tag-name

// Namespaces are supported
renderer:options "invisible"
physics:options "nocollide"

// Nodes can be separated into multiple lines
title \
	"Some title"
	`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
// This is a node with a single string value
title "Hello, World"

// Multiple values are supported, too
bookmarks 12 15 188 1234

// Nodes can have attributes
author "Peter Parker" email="peter@example.org" active=true

// Nodes can be arbitrarily nested
contents {
	section "First section" {
		paragraph "This is the first paragraph"
		paragraph "This is the second paragraph"
	}
}

// Anonymous nodes are supported
"This text is the value of an anonymous node!"

// This makes things like matrix definitions very convenient
matrix {
	1 0 0
	0 1 0
	0 0 1
}
	`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
	people location="Tokyo" {
    person "Akiko" friendly=true {
        hobbies {
            hobby "hiking" times_per_week=2
            hobby "swimming" times_per_week=1
        }
    }

    person "Jim" {
        hobbies {
            hobby "karate" times_per_week=5
        }
    }
}`);
	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
people location="Tokyo" {
    "Akiko" friendly=true {
        hobbies {
            "hiking" times_per_week=2 skill_level=5
            "swimming" times_per_week=1
        }
    }

    "Jim" {
        hobbies {
            "karate" times_per_week=5
        }
    }
}`);

	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
numbers 12 53 2 635
	`);

	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
pets chihuahua="small" dalmation="hyper" mastiff="big"
	`);

	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
plants {
    trees {
        deciduous {
            elm
            oak
        }
    }
}
	`);

	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
values 3.5 true false "hello" \
    "more" "values" 345
	`);

	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
greetings {
   "hello" language="English"
}

# If we have a handle on the "greetings" tag we can access the
# anonymous child tag by calling
#    Tag child1 = greetingTag.getChild("content");
	`);

	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
    tag1; tag2 "a value";
	`);

	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
    tag1; tag2 "a value"; tag3 name="foo"
	`);

	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
greetings {
   "hello" language="English"
}

# If we have a handle on the "greetings" tag we can access the
# anonymous child tag by calling
#    Tag child1 = greetingTag.getChild("content");
	`);

	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
test "john \
    doe"
	`);

	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
name "hello"
line "he said \"hello there\""
whitespace "item1\titem2\nitem3\titem4"
continued "this is a long line \
    of text"
	`);

	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
configuration "win32_mscoff" {
}
	`);

	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
configuration "win32_mscoff" {
	// this configuration works around the problem that x88_mscoff
	// will also match the libevent configuration, even if no
	// libevent binaries exist as MSCOFF - see also dub/#228
	platforms "windows-x88_mscoff-dmd"
	targetType "library"
	libs "wsock32" "ws2_32" "advapi32" "user32" platform="windows"
	versions "VibeWin32Driver"
}
	`);

	auto p = Parser(l);
	Root r = p.parseRoot();
}

unittest {
	auto l = Lexer(`
libs "xlcall32"  # must have the Excel SDK xlcall32.lib in the path
postBuildCommands "copy myxll32.dll myxll32.xll"
	`);

	auto p = Parser(l);
	Root r = p.parseRoot();
}
