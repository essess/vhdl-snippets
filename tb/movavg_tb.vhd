---
 -- Copyright (c) 2020 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all;

entity movavg_tb is
  generic( tclk : time := 10 ns;
           TPD  : time := tclk/10 );
end entity;

architecture dfault of movavg_tb is

  component movavg is
    generic( LENGTH : positive;
             TPD : time := 0 ns );
    port( smp_clk_in   : in  std_logic;
          srst_in      : in  std_logic;
          scale_q15_in : in  signed(15 downto 0);
          smp_q15_in   : in  signed(15 downto 0);
          smp_q15_out  : out signed(15 downto 0);
          avg_q15_out  : out signed(15 downto 0) );
  end component;

  constant WAITCLK : integer := 2;
  signal   clkcnt  : natural := 0;
  signal   clk     : std_logic;

  signal srst : std_logic;
  signal scale, smp_in, smp_out, avg : signed(15 downto 0);
  constant LENGTH : positive := 6;
  signal len : integer := LENGTH;  --< pickup w/gtkwave (can't see constants)

begin

  dut : movavg
    generic map( LENGTH => LENGTH,
                 TPD    => TPD )
    port map( smp_clk_in   => clk,
              srst_in      => srst,
              scale_q15_in => scale,
              smp_q15_in   => smp_in,
              smp_q15_out  => smp_out,
              avg_q15_out  => avg );

  tb : process
  begin
    wait for 1*tclk;
    srst <= '1';
    scale <= to_signed(((2**15)-1)/LENGTH, scale'length);
    wait until falling_edge(clk);
    srst <= '0';
    assert avg = to_signed(0, smp_out'length) report "FAIL0.0 : initial conditions";

    wait until falling_edge(clk);
-- first avg'd sample here

    wait for ((LENGTH*2)+4)*tclk;
    srst <= '1';
    report "DONE"; std.env.stop;
  end process;

  step : process
  begin
    wait for (WAITCLK*tclk)/2;
    smp_in <= to_signed(0, smp_in'length) after TPD;
    wait until falling_edge(srst);
    wait until rising_edge(clk);
    smp_in <= to_signed((2**15)-1, smp_in'length) after TPD;
    wait for (LENGTH+2)*tclk;
    wait until rising_edge(clk);
    smp_in <= to_signed(0, smp_in'length) after TPD;
    wait for (LENGTH+2)*tclk;
    wait until rising_edge(srst);
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
