# https://github.com/collectd/collectd/blob/14c59711e8470798428845ea2ecbdbe28fceb164/src/liboconfig/parser.y#L4
# https://www.rubydoc.info/gems/racc
# https://github.com/ruby/racc/tree/master/doc/en

class CollectdConfigParser
rule
  target: exp { print val }
  
  string:
    QUOTED_STRING
    | UNQUOTED_STRING

  argument:
    NUMBER
    | BTRUE
    | BFALSE
    | string
end
