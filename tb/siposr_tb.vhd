---
 -- Copyright (c) 2019 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all;

entity siposr_tb is
  generic( tclk : time := 10 ns;
           TPD  : time := 1  ns );
end entity;

architecture dfault of siposr_tb is

  component siposr is
    generic( n      : natural;        --< width
             TPD    : time := 0 ns );
    port( clk_in  : in  std_logic;
          srst_in : in  std_logic;
          enb_in  : in  std_logic;    --< shift enable
          d_in    : in  std_logic;
          q_out   : out std_logic_vector(n-1 downto 0) );
  end component;

  constant WAITCLK : integer := 2;
  signal   clkcnt  : natural := 0;
  signal   clk     : std_logic;

  constant n : natural := 4;
  constant rstval : integer := 16#F#;

  signal srst, enb, d : std_logic;
  signal q : std_logic_vector(n-1 downto 0);

begin

  dut : siposr
    generic map( n      => n,
                 TPD    => TPD )
    port map( clk_in  => clk,
              srst_in => srst,
              enb_in  => enb,
              d_in    => d,
              q_out   => q );

  tb : process
  begin
--------------------------------


    wait for 1*tclk;
    srst <= '1';
    d    <= '1';
    wait until clk = '1';
    wait for (1*tclk)/4;
    srst <= '0';
    enb  <= '0';
    wait until clkcnt = 4;

    wait for (1*tclk)/4;
    assert (q = std_logic_vector(to_unsigned(rstval,q'length))) report "FAIL0.0 : initial conditions";


--------------------------------


    wait until clkcnt = 8;
    wait until clk = '0';
    srst <= '1';
    wait until clk = '0';
    srst <= '0';
    enb  <= '1';
    d    <= '0';


--------------------------------


    wait until clkcnt = 16;
    wait until clk = '0';
    srst <= '1';
    wait until clk = '0';
    srst <= '0';
    enb  <= '1';
    d    <= '0';

    wait for 1*tclk;
    enb  <= '0';

    wait for 1*tclk;
    enb  <= '1';

    wait for 1*tclk;
    enb  <= '0';

    wait for 1*tclk;
    enb  <= '1';

    wait for 1*tclk;
    enb  <= '0';

    wait for 1*tclk;
    enb  <= '1';

    wait for 1*tclk;
    enb  <= '0';
    d    <= '1';

    wait for 1*tclk;
    enb  <= '1';

    wait for 1*tclk;
    enb  <= '0';

    wait for 1*tclk;
    enb  <= '1';

    wait for 1*tclk;
    enb  <= '0';

    wait for 1*tclk;
    enb  <= '1';

    wait for 1*tclk;
    enb  <= '0';

    wait for 1*tclk;
    enb  <= '1';


--------------------------------


    wait for 2*tclk;
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
