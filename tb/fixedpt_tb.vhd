---
 -- Copyright (c) 2020 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all,
    ieee.fixed_pkg.all;

entity fixedpt_tb is
  generic( tclk : time := 10 ns;
           TPD  : time := 2  ns );
end entity;

architecture dfault of fixedpt_tb is

  component fixp_adder is
    generic( TPD : time := 0 ns );
    port( a_in  : in  sfixed(0 downto -15);
          b_in  : in  sfixed(0 downto -15);
          c_out : out sfixed(0 downto -15) );
  end component;

  constant WAITCLK : integer := 2;
  signal   clkcnt  : natural := 0;
  signal   clk     : std_logic;

  signal a : sfixed(0 downto -15);  -- Q15
  signal b : sfixed(0 downto -15);  -- Q15
  signal c : sfixed(0 downto -15);  -- Q15
begin

  dut : fixp_adder
    generic map( TPD => TPD )
    port map( a_in  => a,
              b_in  => b,
              c_out => c );

  tb : process
  begin

    -- Q15 : -1 -> +.9999... at resolution of 2**(-15)
    --     : examples demonstrating saturation and ranging
    wait until clkcnt = 1;



    a <= to_sfixed(0.9, a);     -- 0x7333
    b <= to_sfixed(0.9, b);     -- 0x7333
    wait until clkcnt = 2;
    assert to_string(c) = "0.111111111111111" report "FAIL2.0 : +saturation";
    assert to_real(c)   = 9.99969482421875e-1 report "FAIL2.1 : +saturation";

    a <= to_sfixed(0.5, a);     -- 0x4000
    b <= to_sfixed(0.5, b);     -- 0x4000
    wait until clkcnt = 3;
    assert to_string(c) = "0.111111111111111" report "FAIL3.0 : +saturation";
    assert to_real(c)   = 9.99969482421875e-1 report "FAIL3.1 : +saturation";

    a <= to_sfixed(0.5,     a); -- 0x4000
    b <= to_sfixed(0.49997, b); -- 0x3FFF
    wait until clkcnt = 4;
    assert to_string(c) = "0.111111111111111" report "FAIL4.0 : +exact";
    assert to_real(c)   = 9.99969482421875e-1 report "FAIL4.1 : +exact";

    a <= to_sfixed(0.5,     a); -- 0x4000
    b <= to_sfixed(0.49995, b); -- 0x3FFE
    wait until clkcnt = 5;
    assert to_string(c) = "0.111111111111110" report "FAIL5.0 : +exact -0b1";
    assert to_real(c)   = 9.9993896484375e-1  report "FAIL5.1 : +exact -0b1";

    a <= to_sfixed(-0.9, a);    -- 0x8CCD
    b <= to_sfixed(-0.9, b);    -- 0x8CCD
    wait until clkcnt = 6;
    assert to_string(c) = "1.000000000000000" report "FAIL6.0 : -saturation";
    assert to_real(c)   = -1.0                report "FAIL6.1 : -saturation";

    a <= to_sfixed(-0.5, a);    -- 0xC000
    b <= to_sfixed(-0.5, b);    -- 0xC000
    wait until clkcnt = 7;
    assert to_string(c) = "1.000000000000000" report "FAIL7.0 : -exact";
    assert to_real(c)   = -1.0                report "FAIL7.1 : -exact";

    a <= to_sfixed(-0.5, a);    -- 0xC000
    b <= to_sfixed(-0.49998, b);-- 0xC001
    wait until clkcnt = 8;
    assert to_string(c) = "1.000000000000001"  report "FAIL8.0 : -exact +0b1";
    assert to_real(c)   = -9.99969482421875e-1 report "FAIL8.1 : -exact +0b1";

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
