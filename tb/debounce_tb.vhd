---
 -- Copyright (c) 2019 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all;

entity debounce_tb is
  generic( tclk : time := 10 ns;
           TPD  : time := 1  ns;
           n    : integer := 4 );
end entity;

architecture dfault of debounce_tb is

  component debounce is
    generic( n   : integer;             --< number of samples
             TPD : time := 0 ns );
    port( clk_in  : in  std_logic;
          srst_in : in  std_logic;
          enb_in  : in  std_logic;      --< 'sample clk'
          d_in    : in  std_logic;
          q_out   : out std_logic );    --< q <= d upon (2^n) samples
  end component;

  component enbdiv is
    generic( n   : integer;
             TPD : time := 0 ns );
    port( clk_in  : in  std_logic;
          srst_in : in  std_logic;
          enb_out : out std_logic_vector(n downto 1) );   --< enb_out(n) <= clk_in % (2^n)
  end component;

  constant WAITCLK : integer := 2;
  signal   clkcnt  : natural := 0;
  signal   clk     : std_logic;

  signal   enb        : std_logic_vector(n downto 1);
  signal   d, q, srst : std_logic;

begin

  dut : debounce
    generic map( n   => n,
                 TPD => TPD )
    port map( clk_in  => clk,
              srst_in => srst,
              enb_in  => enb(3),  --< clk_in % (2^3) : %8 clk's
              d_in    => d,
              q_out   => q );

  enbdiv0 : enbdiv
    generic map( n   => n,
                 TPD => TPD )
    port map( clk_in  => clk,
              srst_in => srst,
              enb_out => enb );

  tb : process
  begin

    ---------------------------
    wait for 1*tclk;
    srst <= '1';
    d    <= '1';
    wait until clk = '1';
    wait for (1*tclk)/4;
    srst <= '0';
    wait until clkcnt = 4;

    -- q follows d upon reset ?
    assert q = d report "FAIL0.0 : initial conditions";
    ---------------------------

    ---------------------------
    wait for (1*tclk)/4;
    srst <= '1';
    d    <= '0';
    wait until clk = '1';
    wait for (1*tclk)/4;
    srst <= '0';
    wait until clkcnt = 8;

    -- q follows d upon reset ?
    assert q = d report "FAIL0.1 : initial conditions";
    --------------------------

    ---------------------------
    wait for (1*tclk)/4;
    d    <= '1';
    wait until clkcnt = 40; --< enb caught at 39, drive q @ 40, chk'd @ 41
    assert q /= d report "FAIL1.0";
    wait until clkcnt = 41;
    assert q  = d report "FAIL1.1";
    --------------------------

    ---------------------------
    wait for (1*tclk)/4;
    d    <= '0';
    wait until clkcnt = 80; --< enb caught at 79, drive q @ 80, chk'd @ 81-
--  assert q /= d report "FAIL2.0";    ?????
    wait until clkcnt = 81;
    assert q  = d report "FAIL2.1";
    --------------------------

    ---------------------------
    wait until clkcnt = 94;
    wait for (1*tclk)/4;
    d    <= '1';              --< glitch -> RESTART debounce cycle
    wait for 1*tclk;
    d    <= '0';

    -- observe
    --------------------------

    --------------------------
    wait until clkcnt = 132;
    wait for (1*tclk)/4;
    d <= '1';

    wait until clkcnt = 190;
    wait for (1*tclk)/4;
    d <= '0';                 --< glitch -> RESTART debounce cycle
    wait for 1*tclk;
    d <= '1';

    -- observe
    --------------------------

    wait until clkcnt = 230;
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
