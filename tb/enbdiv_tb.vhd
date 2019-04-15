---
 -- Copyright (c) 2019 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all;

entity enbdiv_tb is
  generic( tclk : time := 10 ns;
           TPD  : time := 1  ns );
end entity;

architecture dfault of enbdiv_tb is

  component enbdiv is
    generic( n   : integer;
             TPD : time );
    port( clk_in  : in  std_logic;
          srst_in : in  std_logic;
          enb_out : out std_logic_vector(n downto 1) );
  end component;

  constant n       : integer := 6;
  signal   srst    : std_logic;
  signal   enb     : std_logic_vector(n downto 1);

  constant WAITCLK : integer := 2;
  signal   clkcnt  : natural := 0;
  signal   clk     : std_logic;
begin

  dut : enbdiv
    generic map( n   => n,
                 TPD => TPD )
    port map( clk_in  => clk,
              srst_in => srst,
              enb_out => enb );

  tb : process
  begin
    wait for 1*tclk;
    srst <= '1';
    wait until clk = '1';
    wait for (1*tclk)/4;
    srst <= '0';
    wait for (3*tclk)/4;

    assert (enb = (enb'range => '0')) report "FAIL0.0 : initial conditions";

--  view waveform

    wait for 128*tclk;
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
