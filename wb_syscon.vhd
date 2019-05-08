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
 -- (W)ish(B)one (SYS)tem (CON)troller
 -- minimal, somewhat generic, and adaptable
 --
 -- wishbone signals prefixed with 'wb_'
 --
 -- rst_i -> will typically be taken directly from the outside world
 --          and should be preconditioned and sync'd to clk_i
 --
 -- wb_srst_o -> synchronized to wb_clk_o and stretched for n*wb_clk_o clocks
 --
 -- if a PLL is used here, don't forget to wait for lock!
 --     * do not deassert wb_srst_o until PLL is locked and stretch period complete
 --     * do not drive wb_cl_o until PLL locked
---

entity wb_syscon is
  generic( n   : integer range 0 to (2**5)-1 := (2**5)-1;
           TPD : time := 0 ns );
  port( clk_i      : in  std_logic;
        rst_i      : in  std_logic;
        wb_clk_o   : out std_logic;
        wb_srst_o  : out std_logic );
end entity;

architecture dfault of wb_syscon is

  signal wb_clk, lock : std_logic;
  signal cnt : integer range 0 to (2**5)-1 := n;

begin

  ---------------------------------------------------------------------
  wb_clk <= clk_i;                  --< drop in PLL here (if/as needed)
  lock   <= not(rst_i);
  ---------------------------------------------------------------------

  stretch : process(wb_clk, lock)
  begin
    if not(lock) then
      wb_srst_o <= '1';   --< intercon held in reset until PLL is locked
      cnt <= 0;
    elsif rising_edge(wb_clk) then
      if cnt = n then
        wb_srst_o <= '0'; --< terminal
      else
        wb_srst_o <= '1';
        cnt <= cnt +1;
      end if;
    end if;
  end process;

  wb_clk_o <= wb_clk;

end architecture;