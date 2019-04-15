---
 -- Copyright (c) 2019 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all;

entity incenc_tb is
  generic( n    : positive := 3;
           tclk : time := 10 ns;
           TPD  : time := 1  ns );
end entity;

architecture dfault of incenc_tb is

  component incenc is
    generic( n   : positive;          --< counter width
             TPD : time := 0 ns );
    port( clk_in  : in  std_logic;
          srst_in : in  std_logic;
          a_in    : in  std_logic;
          b_in    : in  std_logic;
          cnt_out : out unsigned(n-1 downto 0) );
  end component;

  constant WAITCLK : integer := 2;
  signal   clkcnt  : natural := 0;
  signal   clk     : std_logic;

  signal ccw, cw : std_logic;
  signal srst, a, b : std_logic;
  signal cnt : unsigned(n-1 downto 0);

begin

  dut : incenc
    generic map( n   => n,
                 TPD => TPD )
    port map( clk_in  => clk,
              srst_in => srst,
              a_in    => a,
              b_in    => b,
              cnt_out => cnt );

  tb : process
  begin

    ---------------------------------
    wait for 1*tclk;
    srst <= '1';
    wait until clk = '1';
    wait for (1*tclk)/4;
    srst <= '0';
    wait until clkcnt = 3;

    assert cnt = 0 report "FAIL0.0 : initial conditions";
    ---------------------------------

    ---------------------------------
    wait until clkcnt = 512;
    wait for (1*tclk)/4;
    srst <= '1';
    wait for 1*tclk;
    srst <= '0';
    wait until clk = '1';

    -- srst gets priority over a/b edges
    assert cnt = 0 report "FAIL1.0";
    ---------------------------------

    -- TODO: test that illegal states are rejected correctly

    wait for 512*tclk;
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

  encoder : process
    constant cycles : integer := 8;
  begin
    ccw <= '0';
    cw  <= '0';
    a   <= '1';
    b   <= '0';
    wait until clk = '1';
    wait for (1*tclk)/8;  --< offset
    loop
      ccw <= '1'; --< b leads a
      cw  <= '0';
      wait for 4*tclk;
      for i in 1 to cycles loop --< up for 4 cycles
        a <= '1';
        b <= '0'; wait for 4*tclk;
        a <= '0';
        b <= '0'; wait for 4*tclk;
        a <= '0';
        b <= '1'; wait for 4*tclk;
        a <= '1';
        b <= '1'; wait for 4*tclk;
      end loop;
      ccw <= '0'; --< a leads b
      cw  <= '1';
      wait for 4*tclk;
      for i in 1 to cycles loop --< down for 4 cycles
        a <= '0';
        b <= '1'; wait for 4*tclk;
        a <= '0';
        b <= '0'; wait for 4*tclk;
        a <= '1';
        b <= '0'; wait for 4*tclk;
        a <= '1';
        b <= '1'; wait for 4*tclk;
      end loop;
    end loop;
  end process;

end architecture;
