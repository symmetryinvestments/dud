module dud.sdlang2.ast;

import dud.sdlang2.tokenmodule;

import dud.sdlang2.visitor;

@safe pure:

class Node {}

enum RootEnum {
	T,
	E,
}

class Root : Node {
@safe pure:

	RootEnum ruleSelection;
	Tags tags;

	this(RootEnum ruleSelection, Tags tags) {
		this.ruleSelection = ruleSelection;
		this.tags = tags;
	}

	this(RootEnum ruleSelection) {
		this.ruleSelection = ruleSelection;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum TagsEnum {
	Tag,
	TagFollow,
}

class Tags : Node {
@safe pure:

	TagsEnum ruleSelection;
	Tag tag;
	Tags follow;

	this(TagsEnum ruleSelection, Tag tag) {
		this.ruleSelection = ruleSelection;
		this.tag = tag;
	}

	this(TagsEnum ruleSelection, Tag tag, Tags follow) {
		this.ruleSelection = ruleSelection;
		this.tag = tag;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum TagEnum {
	VAO,
	AO,
	VO,
	VA,
	O,
	A,
	V,
	E,
	VAOT,
	AOT,
	VOT,
	VAT,
	OT,
	AT,
	VT,
	ET,
}

class Tag : Node {
@safe pure:

	TagEnum ruleSelection;
	OptChild oc;
	IDFull id;
	Values vals;
	Attributes attrs;

	this(TagEnum ruleSelection, IDFull id, Values vals, Attributes attrs, OptChild oc) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.vals = vals;
		this.attrs = attrs;
		this.oc = oc;
	}

	this(TagEnum ruleSelection, IDFull id, Attributes attrs, OptChild oc) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.attrs = attrs;
		this.oc = oc;
	}

	this(TagEnum ruleSelection, IDFull id, Values vals, OptChild oc) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.vals = vals;
		this.oc = oc;
	}

	this(TagEnum ruleSelection, IDFull id, Values vals, Attributes attrs) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.vals = vals;
		this.attrs = attrs;
	}

	this(TagEnum ruleSelection, IDFull id, OptChild oc) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.oc = oc;
	}

	this(TagEnum ruleSelection, IDFull id, Attributes attrs) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.attrs = attrs;
	}

	this(TagEnum ruleSelection, IDFull id, Values vals) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.vals = vals;
	}

	this(TagEnum ruleSelection, IDFull id) {
		this.ruleSelection = ruleSelection;
		this.id = id;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum IDFullEnum {
	L,
	S,
}

class IDFull : Node {
@safe pure:

	IDFullEnum ruleSelection;
	IDSuffix suff;
	Token id;

	this(IDFullEnum ruleSelection, Token id, IDSuffix suff) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.suff = suff;
	}

	this(IDFullEnum ruleSelection, Token id) {
		this.ruleSelection = ruleSelection;
		this.id = id;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum IDSuffixEnum {
	C,
	F,
}

class IDSuffix : Node {
@safe pure:

	IDSuffixEnum ruleSelection;
	IDSuffix follow;
	Token id;

	this(IDSuffixEnum ruleSelection, Token id) {
		this.ruleSelection = ruleSelection;
		this.id = id;
	}

	this(IDSuffixEnum ruleSelection, Token id, IDSuffix follow) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum ValuesEnum {
	Value,
	ValueFollow,
}

class Values : Node {
@safe pure:

	ValuesEnum ruleSelection;
	Token value;
	Values follow;

	this(ValuesEnum ruleSelection, Token value) {
		this.ruleSelection = ruleSelection;
		this.value = value;
	}

	this(ValuesEnum ruleSelection, Token value, Values follow) {
		this.ruleSelection = ruleSelection;
		this.value = value;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum AttributesEnum {
	Attribute,
	AttributeFollow,
}

class Attributes : Node {
@safe pure:

	AttributesEnum ruleSelection;
	Attribute attr;
	Attributes follow;

	this(AttributesEnum ruleSelection, Attribute attr) {
		this.ruleSelection = ruleSelection;
		this.attr = attr;
	}

	this(AttributesEnum ruleSelection, Attribute attr, Attributes follow) {
		this.ruleSelection = ruleSelection;
		this.attr = attr;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum AttributeEnum {
	A,
}

class Attribute : Node {
@safe pure:

	AttributeEnum ruleSelection;
	Token value;
	IDFull id;

	this(AttributeEnum ruleSelection, IDFull id, Token value) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.value = value;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum OptChildEnum {
	C,
}

class OptChild : Node {
@safe pure:

	OptChildEnum ruleSelection;
	Tags tags;

	this(OptChildEnum ruleSelection, Tags tags) {
		this.ruleSelection = ruleSelection;
		this.tags = tags;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum TagTerminatorEnum {
	E,
	S,
}

class TagTerminator : Node {
@safe pure:

	TagTerminatorEnum ruleSelection;

	this(TagTerminatorEnum ruleSelection) {
		this.ruleSelection = ruleSelection;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

