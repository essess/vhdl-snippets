---
 -- Copyright (c) 2020 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all;

---
 -- ADS-B mode s (PRE)amble (DET)ect
 --
 -- ASSUMES 4 SAMPLES/SYMBOL
 --
 -- sample state  >>  symbol name
 --       0b0000  >>  L
 --       0b1111  >>  H
 --       0b1100  >>  1
 --       0b0011  >>  0
 --         else  >>  n/a
---

entity predet is
  generic( TPD : time := 0 ns );
  port( smp_clk_in   : in  std_logic;
        srst_in      : in  std_logic;
        smp_in       : in  unsigned(15 downto 0);
        threshold_in : in  unsigned(15 downto 0);
        smp_out      : out unsigned(15 downto 0);
        valid_out    : out std_logic );
end entity;

architecture dfault of predet is

  signal smp   : unsigned(smp_in'range);
  signal value : std_logic;   --< is current sample interpreted as a '1' or '0'?
  signal valid : std_logic;   --< mode s preamble detected?

  type state_t is ( idle, -- s<<RESOLVED SYMBOL>>_<<RESOLVED SAMPLE>>
                    sxxxxxxx_1xxx, sxxxxxxx_11xx, sxxxxxxx_110x, sxxxxxxx_1100,
                    s1xxxxxx_1xxx, s1xxxxxx_11xx, s1xxxxxx_110x, s1xxxxxx_1100,
                    s11xxxxx_0xxx, s11xxxxx_00xx, s11xxxxx_000x, s11xxxxx_0000,
                    s11Lxxxx_0xxx, s11Lxxxx_00xx, s11Lxxxx_001x, s11Lxxxx_0011,
                    s11L0xxx_0xxx, s11L0xxx_00xx, s11L0xxx_001x, s11L0xxx_0011,
                    s11L00xx_0xxx, s11L00xx_00xx, s11L00xx_000x, s11L00xx_0000,
                    s11L00Lx_0xxx, s11L00Lx_00xx, s11L00Lx_000x, s11L00Lx_0000,
                    s11L00LL_0xxx, s11L00LL_00xx, s11L00LL_000x, s11L00LL_0000 );
                        -- state s11L00LLL aka PREAMBLE DETECTED ^^^^^^^^^^^^^
  signal state, next_state : state_t;

begin

  -- state / registered
  process(smp_clk_in)
  begin
    if rising_edge(smp_clk_in) then
      if(srst_in = '1') then
        state <= idle;
      else
        state <= next_state;
      end if;
      smp_out   <= smp_in after TPD;
      valid_out <= valid  after TPD;
    end if;
  end process;


  -- decide how to interpret the value of this sample
  -- based upon the current threshold magnitude
  value <= '1' when (smp_in > threshold_in) else '0'; --< brute force it!


  -- next state / combinational
  process(state, value)
  begin
    valid <= '0'; --<< default output unless in the final state
    case state is
      when sxxxxxxx_1xxx =>
        if value = '0' then next_state <=          idle;
        else                next_state <= sxxxxxxx_11xx; end if;
      when sxxxxxxx_11xx =>
        if value = '0' then next_state <= sxxxxxxx_110x;
        else                next_state <= sxxxxxxx_11xx; end if;
      when sxxxxxxx_110x =>
        if value = '0' then next_state <= sxxxxxxx_1100;
        else                next_state <= sxxxxxxx_1xxx; end if;
      when sxxxxxxx_1100 => --<< 1100.xxxx.xxxx.xxxx.xxxx.xxxx.xxxx.xxxx >>--
        if value = '0' then next_state <=          idle;
        else                next_state <= s1xxxxxx_1xxx; end if;

      when s1xxxxxx_1xxx =>
        if value = '0' then next_state <=          idle;
        else                next_state <= s1xxxxxx_11xx; end if;
      when s1xxxxxx_11xx =>
        if value = '0' then next_state <= s1xxxxxx_110x;
        else                next_state <= sxxxxxxx_11xx; end if;
      when s1xxxxxx_110x =>
        if value = '0' then next_state <= s1xxxxxx_1100;
        else                next_state <= sxxxxxxx_1xxx; end if;
      when s1xxxxxx_1100 => --<< 1100.1100.xxxx.xxxx.xxxx.xxxx.xxxx.xxxx >>--
        if value = '0' then next_state <= s11xxxxx_0xxx;
        else                next_state <= s1xxxxxx_1xxx; end if;

      when s11xxxxx_0xxx =>
        if value = '0' then next_state <= s11xxxxx_00xx;
        else                next_state <= sxxxxxxx_1xxx; end if;
      when s11xxxxx_00xx =>
        if value = '0' then next_state <= s11xxxxx_000x;
        else                next_state <= sxxxxxxx_1xxx; end if;
      when s11xxxxx_000x =>
        if value = '0' then next_state <= s11xxxxx_0000;
        else                next_state <= sxxxxxxx_1xxx; end if;
      when s11xxxxx_0000 => --<< 1100.1100.0000.xxxx.xxxx.xxxx.xxxx.xxxx >>--
        if value = '0' then next_state <= s11Lxxxx_0xxx;
        else                next_state <= sxxxxxxx_1xxx; end if;

      when s11Lxxxx_0xxx =>
        if value = '0' then next_state <= s11Lxxxx_00xx;
        else                next_state <= sxxxxxxx_1xxx; end if;
      when s11Lxxxx_00xx =>
        if value = '0' then next_state <=          idle;
        else                next_state <= s11Lxxxx_001x; end if;
      when s11Lxxxx_001x =>
        if value = '0' then next_state <=          idle;
        else                next_state <= s11Lxxxx_0011; end if;
      when s11Lxxxx_0011 => --<< 1100.1100.0000.0011.xxxx.xxxx.xxxx.xxxx >>--
        if value = '0' then next_state <= s11L0xxx_0xxx;
        else                next_state <= sxxxxxxx_11xx; end if;

      when s11L0xxx_0xxx =>
        if value = '0' then next_state <= s11L0xxx_00xx;
        else                next_state <= sxxxxxxx_1xxx; end if;
      when s11L0xxx_00xx =>
        if value = '0' then next_state <=          idle;
        else                next_state <= s11L0xxx_001x; end if;
      when s11L0xxx_001x =>
        if value = '0' then next_state <=          idle;
        else                next_state <= s11L0xxx_0011; end if;
      when s11L0xxx_0011 => --<< 1100.1100.0000.0011.0011.xxxx.xxxx.xxxx >>--
        if value = '0' then next_state <= s11L00xx_0xxx;
        else                next_state <= sxxxxxxx_11xx; end if;

      when s11L00xx_0xxx =>
        if value = '0' then next_state <= s11L00xx_00xx;
        else                next_state <= sxxxxxxx_1xxx; end if;
      when s11L00xx_00xx =>
        if value = '0' then next_state <= s11L00xx_000x;
        else                next_state <= s1xxxxxx_1xxx; end if;
      when s11L00xx_000x =>
        if value = '0' then next_state <= s11L00xx_0000;
        else                next_state <= sxxxxxxx_1xxx; end if;
      when s11L00xx_0000 => --<< 1100.1100.0000.0011.0011.0000.xxxx.xxxx >>--
        if value = '0' then next_state <= s11L00Lx_0xxx;
        else                next_state <= sxxxxxxx_1xxx; end if;

      when s11L00Lx_0xxx =>
        if value = '0' then next_state <= s11L00Lx_00xx;
        else                next_state <= sxxxxxxx_1xxx; end if;
      when s11L00Lx_00xx =>
        if value = '0' then next_state <= s11L00Lx_000x;
        else                next_state <= sxxxxxxx_1xxx; end if;
      when s11L00Lx_000x =>
        if value = '0' then next_state <= s11L00Lx_0000;
        else                next_state <= sxxxxxxx_1xxx; end if;
      when s11L00Lx_0000 => --<< 1100.1100.0000.0011.0011.0000.0000.xxxx >>--
        if value = '0' then next_state <= s11L00LL_0xxx;
        else                next_state <= sxxxxxxx_1xxx; end if;

      when s11L00LL_0xxx =>
        if value = '0' then next_state <= s11L00LL_00xx;
        else                next_state <= sxxxxxxx_1xxx; end if;
      when s11L00LL_00xx =>
        if value = '0' then next_state <= s11L00LL_000x;
        else                next_state <= sxxxxxxx_1xxx; end if;
      when s11L00LL_000x =>
        if value = '0' then next_state <= s11L00LL_0000;
        else                next_state <= sxxxxxxx_1xxx; end if;
      when s11L00LL_0000 => --<< 1100.1100.0000.0011.0011.0000.0000.0000 >>--
        if value = '0' then next_state <=          idle;
        else                next_state <= sxxxxxxx_1xxx; end if;
        valid <= '1';

      when others => --<< idle >>--
        if value = '0' then next_state <=          idle;
        else                next_state <= sxxxxxxx_1xxx; end if;
    end case;
  end process;

end architecture;