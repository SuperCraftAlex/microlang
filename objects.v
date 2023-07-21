module main

struct LOCATION {
	mut:
	in_stack bool	// means that it is in the top of the stack

	in_reg bool
	reg string

	addr i64
}

pub fn (s LOCATION) str() string {
	mut o := []string {}
	o << "{"

	if s.in_reg {
		o << "\"register\": \"${s.reg}\""
	}
	else if s.in_stack {
		o << "\"stack\": 0"
	}
	else {
		o << "\"address\": \"${s.addr}\""
	}

	o << "}"
	return o.join("")
}

struct TYPE {
	mut:
	size u8
	name string

	group string

	public bool
	notypecheck bool
}

pub fn (t TYPE) str() string {
	mut o := []string {}
	o << "{"
	o << "\"name\": \"${t.name}\","
	o << "\"size\": ${t.size},"
	if t.group.len > 0 {
		o << "\"group\": \"${t.group}\","
	}
	o << "\"public\": ${t.public},"
	o << "\"notypecheck\": ${t.notypecheck}"
	o << "}"
	return o.join("")
}

struct VAR {
	mut:
	location &LOCATION = unsafe { nil }
	name string
	typ string

	pointerc int	// amount of "*" infront of the variable name

	fixed_to_ram bool
	fixed_to_stack bool
}

pub fn (s VAR) str() string {
	mut o := []string {}
	o << "{"
	if s.name != "_retv" {
		o << "\"name\": \"${s.name}\","
	}
	o << "\"type\": \"${s.typ}\","

	if s.location != unsafe { nil } {
		o << "\"location\": ${s.location.str()},"
	}

	if s.pointerc > 0 {
		o << "\"pointer_count\": ${s.pointerc}"
	}

	if s.fixed_to_ram {
		o << "\"fixed_to\": \"ram\""
	}
	else if s.fixed_to_stack {
		o << "\"fixed_to\": \"stack\""
	}

	o << "}"
	return o.join("")
}


struct FUNC {
	mut:
	location &LOCATION = unsafe { nil }

	isfunc bool
	args []&VAR
	retv &VAR = unsafe { nil }

	name string
	public bool

	code []string
	p_code []&PARSEOUT

	macro bool
	automacro bool
}

pub fn (f FUNC) str() string {
	mut o := []string {}
	o << "{"
	o << "\"name\": \"${f.name}\","
	o << "\"public\": ${f.public},"

	if f.isfunc {
		o << "\"type\": \"function\","
	}
	else {
		o << "\"type\": \"block\","
	}

	if f.location != unsafe { nil } {
		o << "\"location\": ${f.location.str()},"
	}

	if f.retv != unsafe { nil } {
		o << "\"returns\": ${(*f.retv).str()},"
	}

	if f.args.len > 0 {
		o << "\"args\": ["
		for arg in f.args {
			o << (*arg).str() + ","
		}
		o << "],"
	}

	o << "\"code\": ["
	for c in f.p_code {
		o << c.str() + ","
	}
	o << "]}"
	return o.join("")
}

struct STRUCT {
	mut:
	name string
	public bool

	variables []VAR		// address of var.location is offset!!
}


pub fn (s STRUCT) str() string {
	mut o := []string {}
	o << "{"
	o << "\"name\": \"${s.name}\","
	o << "\"public\": ${s.public},"

	o << "\"members\": ["
	for var in s.variables {
		o << "{\"name\": \"${var.name}\", \"type\": \"${var.typ}\"},"
	}

	o << "]}"
	return o.join("")
}