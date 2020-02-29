---
 -- Copyright (c) 2020 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all;

entity cplxtomag_tb is
  generic( tclk : time := 10 ns;
           TPD  : time := 1  ns );
end entity;

architecture dfault of cplxtomag_tb is

  component cplxtomag is
    generic( TPD : time := 0 ns );
    port( smp_clk_in    : in  std_logic;
          srst_in       : in  std_logic;
          a_q15_in      : in  signed(15 downto 0);
          b_q15_in      : in  signed(15 downto 0);
          magsq_q15_out : out signed(15 downto 0) );
  end component;

  constant WAITCLK : integer := 2;
  signal   clkcnt  : natural := 0;
  signal   clk     : std_logic;

  signal srst : std_logic;
  signal a, b, magsq : signed(15 downto 0) := (others=>'0');

begin

  dut : cplxtomag
    generic map( TPD => TPD )
    port map( smp_clk_in    => clk,
              srst_in       => srst,
              a_q15_in      => a,
              b_q15_in      => b,
              magsq_q15_out => magsq );

  tb : process
  begin

    wait for 1*tclk;
    srst <= '1';
    a <= to_signed(-1, a'length);       --< -0.000030519 (Q1.15)
    b <= to_signed(-1, b'length);       --< -0.000030519 (Q1.15)
    wait until rising_edge(clk);

    wait until falling_edge(clk);
    assert magsq = to_signed(0, magsq'length)
      report "FAIL1.0 : 16#" & to_hstring(magsq) & "# : initial conditions";

    srst <= '0';
    a <= to_signed(32767, a'length);    --< +0.99996948 (+MAX Q1.15)
    b <= to_signed(32767, b'length);    --< +0.99996948 (+MAX Q1.15)
    -- a^2 + b^2 = +1.999877932 (Q2.14 : 32766)
    -- normalizes to: +0.9999389648 (Q1.15 : 32766)
    wait until rising_edge(clk);

    wait until falling_edge(clk);
    assert magsq = to_signed(32766, magsq'length)
      report "FAIL2.0 : 16#" & to_hstring(magsq) & "# : (+MAX Q1.15)^2 + (+MAX Q1.15)^2 = (Q1.15 +MAX-1)";
    -- ^^ check
    --
    a <= to_signed(-32768, a'length);   --< -1.00000000 (-MAX Q1.15)
    b <= to_signed(-32768, b'length);   --< -1.00000000 (-MAX Q1.15)
    -- a^2 + b^2 = +1.999877932 (Q2.14 : 32766)
    -- normalizes to: +0.9999389648 (Q1.15 : 32766)
    -- see notes in cplxtomag for details as to why implemented this way
    wait until rising_edge(clk);

    wait until falling_edge(clk);
    assert magsq = to_signed(32766, magsq'length)
      report "FAIL3.0 : 16#" & to_hstring(magsq) & "# : (-MAX Q1.15)^2 + (-MAX Q1.15)^2 = (Q1.15 +MAX-1)";
    -- ^^ check
    --
    a <= to_signed(-16384, a'length);   --< -0.50000000 (Q1.15)
    b <= to_signed(-16384, b'length);   --< -0.50000000 (Q1.15)
    -- a^2 + b^2 = +0.50000000 (Q2.14 : 8192)
    -- normalizes to: +0.25000000 (Q1.15 : 8192)
    wait until rising_edge(clk);

    wait until falling_edge(clk);
    assert magsq = to_signed(8192, magsq'length)
      report "FAIL4.0 : 16#" & to_hstring(magsq) & "# : (-0.5)^2 + (-0.5)^2 = +1/4th Q1.15 +ive range";
    -- ^^ check
    --
    a <= to_signed(23170, a'length);    --< ~sqrt(1/2)^2 (Q1.15)
    b <= to_signed(23170, b'length);    --< ~sqrt(1/2)^2 (Q1.15)
    -- a^2 + b^2 = +0.9999389648 (Q2.14 : 16383)
    -- normalizes to: +0.4999694824 (Q1.15 : 16383)
    wait until rising_edge(clk);

    wait until falling_edge(clk);
    assert magsq = to_signed(16383, magsq'length)
      report "FAIL5.0 : 16#" & to_hstring(magsq) & "# : (sqrt(1/2))^2 + (sqrt(1/2))^2 = +1/2 Q1.15 +ive range";
    -- ^^ check
    --
    a <= to_signed(4096, a'length);     --< +0.125 (Q1.15)
    b <= to_signed(-4096, b'length);    --< -0.125 (Q1.15)
    -- a^2 + b^2 = +0.03125 (Q2.14 : 512)
    -- normalizes to: +0.015625 (Q1.15 : 512)
    wait until rising_edge(clk);

    wait until falling_edge(clk);
    assert magsq = to_signed(512, magsq'length)
      report "FAIL6.0 : 16#" & to_hstring(magsq) & "# : (+0.125)^2 + (-0.125)^2 = +0.015625";
    -- ^^ check
    --
    a <= to_signed(31000, a'length);    --< +0.9460449 (Q1.15)
    b <= to_signed(-32400, b'length);   --< -0.9887695 (Q1.15)
    -- a^2 + b^2 = +1.87261963 (Q2.14 : 30681 *FLOORED*)
    -- normalizes to: +0.93630981 (Q1.15 : 30681)
    wait until rising_edge(clk);

    wait until falling_edge(clk);
    assert magsq = to_signed(30681, magsq'length)
      report "FAIL7.0 : 16#" & to_hstring(magsq) & "# : (+0.9460449)^2 + (-0.9887695)^2 = +0.93630981";
    -- ^^ check
    --
    a <= to_signed(61, a'length);       --< +0.00186157 (Q1.15)
    b <= to_signed(-254, b'length);     --< -0.00775146 (Q1.15)
    -- a^2 + b^2 = +0.00006104 (Q2.14 : 1)
    -- normalizes to: +0.00003052 (Q1.15 : 1)
    wait until rising_edge(clk);

    wait until falling_edge(clk);
    assert magsq = to_signed(1, magsq'length)
      report "FAIL8.0 : 16#" & to_hstring(magsq) & "# : (+0.00186157)^2 + (-0.00775146)^2 = +0.00003052";
    -- ^^ check
    --


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
