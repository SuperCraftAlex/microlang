module argparser

struct ARG {
	name string
	values []string
}

pub fn parse(a []string) []&ARG {
	mut out := []&ARG {}

	mut current := ""
	mut vals := []string {}

	for s in a {
		if s.starts_with("-") {
			if vals.len > 0 || current.len > 0 {
				out << &ARG {
					name: current
					values: vals
				}
			}
			current = s[1..]
			vals = []
			continue
		}
		vals << s
	}
	if vals.len > 0 || current.len > 0 {
		out << &ARG {
			name: current
			values: vals
		}
	}

	return out
}

pub fn (argl []&ARG) check_args(allowed_args []string) ! {
	for a in argl {
		if a.name !in allowed_args {
			return error("Argument ${a.name} not allowed!")
		}
	}
}

pub fn (argl []&ARG) has_arg(name string) bool {
	for a in argl {
		if a.name == name {
			return true
		}
	}
	return false
}

pub fn (argl []&ARG) get_arg(name string) ![]string {
	for a in argl {
		if a.name == name {
			return a.values
		}
	}
	return error("Argument not found!")
}