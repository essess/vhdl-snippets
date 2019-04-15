---
 -- Copyright (c) 2019 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all;

---
 -- (D)escription
---

entity ... is
  generic( ...
           TPD : time := 0 ns );
  port( clk_in  : in  std_logic;
        srst_in : in  std_logic;
        enb_in  : in  std_logic;
        ... );
end entity;

architecture dfault of ... is

  signal q : std_logic_vector(n-1 downto 0);

begin
  assert (n >= 2) report "minimum width (n) is 2" severity failure;

  shift : process(clk_in, srst_in, enb_in, ...)
  begin
    if rising_edge(clk_in) then
      ...
    end if;
  end process;

  -- output
  q_out <= q after TPD;

end architecture;