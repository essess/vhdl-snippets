---
 -- Copyright (c) 2019 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all;

--
-- (EN)a(B)le (DIV)ider
-- creates 'n' enable taps that are synchronous to clk,
-- generation of enb_out(0) is skipped (/1 is useless!).
--

entity enbdiv is
  generic( n   : integer;
           TPD : time := 0 ns );
  port( clk_in  : in  std_logic;
        srst_in : in  std_logic;
        enb_out : out std_logic_vector(n downto 1) );   --< enb_out(n) <= clk_in % (2^n)
end entity;

architecture dfault of enbdiv is

  signal cnt : unsigned(n downto 0);
  signal enb : std_logic_vector(enb_out'range);

begin
  assert (n >= 1) report "minimum tap count (n) is 1" severity failure;

  counter : process(clk_in)
  begin
    if rising_edge(clk_in) then
      if srst_in then
        cnt <= (others=>'0');
      else
        cnt <= cnt +1;
      end if;
    end if;
  end process;

  --
  -- sync counter 'taps' to clk_in to generate enable ticks
  -- the lowest order tap (n=1) divides by /2, the next is /4, etc
  --
  -- in other words:
  --    enb_out(n) <= clk_in % (2^n)
  --

  enable : process(clk_in)
    variable prevcnt : unsigned(cnt'range);
  begin
    if rising_edge(clk_in) then
      enb <= (others=>'0');
      if srst_in then
        prevcnt := (others=>'0');
      else
        for i in enb'range loop
          if cnt(i) /= prevcnt(i) then
            enb(i) <= '1';
          end if;
        end loop;
        prevcnt := cnt;
      end if;
    end if;
  end process;

  -- output
  enb_out <= enb after TPD;

end architecture;