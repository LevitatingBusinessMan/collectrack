# Rexical version of 
# https://github.com/collectd/collectd/blob/14c59711e8470798428845ea2ecbdbe28fceb164/src/liboconfig/scanner.l
class CollectdConfigParser
macro
  WHITE_SPACE [\ \t\b]
  NON_WHITE_SPACE [^\ \t\b]
  EOL (\r\n|\n)
  QUOTED_STRING ([^\\"]+|\\.)*
  UNQUOTED_STRING [0-9A-Za-z_]+
  HEX_NUMBER 0[xX][0-9a-fA-F]+
  OCT_NUMBER 0[0-7]+
  DEC_NUMBER [\+\-]?[0-9]+
  FLOAT_NUMBER [\+\-]?[0-9]*\.[0-9]+([eE][\+\-][0-9]+)?
  NUMBER ({FLOAT_NUMBER}|{HEX_NUMBER}|{OCT_NUMBER}|{DEC_NUMBER})
  BOOL_TRUE (true|yes|on)
  BOOL_FALSE (false|no|off)
  COMMENT \#.*
  PORT (6(5(5(3[0-5]|[0-2][0-9])|[0-4][0-9][0-9])|[0-4][0-9][0-9][0-9])|[1-5][0-9][0-9][0-9][0-9]|[1-9][0-9]?[0-9]?[0-9]?)

  IP_BYTE (2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])
  IPV4_ADDR {IP_BYTE}\.{IP_BYTE}\.{IP_BYTE}\.{IP_BYTE}(:{PORT})?

  /* IPv6 address according to http://www.ietf.org/rfc/rfc2373.txt
  * This supports embedded IPv4 addresses as well but does not strictly check
  * for the right prefix (::0:<v4> or ::FFFF:<v4>) because there are too many
  * ways to correctly represent the zero bytes. It's up to the user to check
  * for valid addresses. */
  HEX16 ([0-9A-Fa-f]{1,4})
  V6_PART ({HEX16}:{HEX16}|{IPV4_ADDR})
  IPV6_BASE ({HEX16}:){6}{V6_PART}|::({HEX16}:){5}{V6_PART}|({HEX16})?::({HEX16}:){4}{V6_PART}|(({HEX16}:){0,1}{HEX16})?::({HEX16}:){3}{V6_PART}|(({HEX16}:){0,2}{HEX16})?::({HEX16}:){2}{V6_PART}|(({HEX16}:){0,3}{HEX16})?::{HEX16}:{V6_PART}|(({HEX16}:){0,4}{HEX16})?::{V6_PART}|(({HEX16}:){0,5}{HEX16})?::{HEX16}|(({HEX16}:){0,6}{HEX16})?::
  IPV6_ADDR ({IPV6_BASE})|(\[{IPV6_BASE}\](:{PORT})?)
rule
  {WHITE_SPACE}         # ignore
  {COMMENT}             # ignore

  \\{EOL}               # continue line

  {EOL}                 { [:EOL, text] }
  \/                    { [:SLASH, text] }
  <                     { [:OPENBRAC, text] }
  >                     { [:CLOSEBRAC, text] }

  {BOOL_TRUE}           { [:BTRUE, true] }
  {BOOL_FALSE}          { [:BFALSE, false] }

  {IPV4_ADDR}           { [:UNQUOTED_STRING, text] }
  {IPV6_ADDR}           { [:UNQUOTED_STRING, text] }

  {NUMBER}              { [:NUMBER, Integer(text)] }

  \"{QUOTED_STRING}\"   { [:QUOTED_STRING, text] }
  {UNQUOTED_STRING}     { [:UNQUOTED_STRING, text] }
  .                     { raise "Failure to match #{text}" }
inner
  def tokens(str)
    scan_setup(str)
    tokens = []
    while token = next_token
      tokens << token 
    end
    tokens
  end
end
