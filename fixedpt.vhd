---
 -- Copyright (c) 2020 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all,
    ieee.fixed_pkg.all;

---
 -- (FIX)ed (P)oint (ADDER) examples
 -- take fixed_pkg (added in VHDL-2008) for a little test run.
---

entity fixp_adder is
  generic( TPD : time := 0 ns );
  port( a_in  : in  sfixed(0 downto -15);
        b_in  : in  sfixed(0 downto -15);
        c_out : out sfixed(0 downto -15) );
end entity;

architecture dfault of fixp_adder is
begin
  c_out <= resize( (a_in + b_in), c_out ) after TPD;
end architecture;