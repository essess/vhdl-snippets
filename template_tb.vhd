---
 -- Copyright (c) 2019 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all;

entity ...._tb is
  generic( tclk : time := 10 ns;
           TPD  : time := 1  ns );
end entity;

architecture dfault of ...._tb is

  component ... is
    port( .... );
  end component;

  constant WAITCLK : integer := 2;
  signal   clkcnt  : natural := 0;
  signal   clk     : std_logic;
begin

  dut : ....
    port map( .... );

  tb : process
  begin

    wait for 1*tclk;
    srst <= '1';
--  d    <= '1';
    wait until clk = '1';
    wait for (1*tclk)/4;
    srst <= '0';
    enb  <= '0';
    wait until clkcnt = 4;

    assert .... report "FAIL0.0 : initial conditions";

	-- tests here

    wait for 1*tclk;
    report "DONE"; std.env.stop;
  end process;

  sysclk : process
  begin
    wait for WAITCLK*tclk;
    loop
      clk <= '0'; wait for tclk/2;
      clk <= '1'; clkcnt <= clkcnt +1;
                  wait for tclk/2;
    end loop;
  end process;

end architecture;
