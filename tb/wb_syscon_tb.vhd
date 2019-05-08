---
 -- Copyright (c) 2019 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all;

entity wb_syscon_tb is
  generic( tclk : time := 10 ns;
           TPD  : time := 2  ns );
end entity;

architecture dfault of wb_syscon_tb is

  component wb_syscon is
    generic( n   : integer range 0 to (2**5)-1 := (2**5)-1;
             TPD : time := 0 ns );
    port( clk_i      : in  std_logic;
          rst_i      : in  std_logic;
          wb_clk_o   : out std_logic;
          wb_srst_o  : out std_logic );
  end component;

  constant WAITCLK : integer := 2;
  signal   clkcnt  : natural := 0;
  signal   clk     : std_logic;

  signal rst, wb_clk, wb_srst : std_logic;

begin

  dut : wb_syscon
    generic map( n => 7 )
    port map( clk_i     => clk,
              rst_i     => rst,
              wb_clk_o  => wb_clk,
              wb_srst_o => wb_srst );

  tb : process
  begin

    wait for 1*tclk;
    rst <= '1';
    wait until clkcnt = 3;
    wait until falling_edge(clk);
    rst <= '0';

    -- tests here

    wait until clkcnt = 12;
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
