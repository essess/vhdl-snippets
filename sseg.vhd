---
 -- Copyright (c) 2019 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all;

---
 -- (S)even-(SEG)ment driver/decoder for my cheapo Spartan6 devboard
---

entity sseg is
  port( value_in     : in  unsigned(15 downto 0);
        clk_in       : in  std_logic;
        srst_in      : in  std_logic;
        blank_in     : in  std_logic;
        step_in      : in  std_logic;     --< step to cycle through digits
        anodedrv_out : out std_logic_vector(3 downto 0);
        segments_out : out std_logic_vector(6 downto 0) );
end entity;

architecture dfault of sseg is

  signal anodedrv : std_logic_vector(anodedrv_out'range);
  signal digit    : unsigned(3 downto 0);

begin

  process(clk_in)
    type state_t is ( DIG0, DIG1, DIG2, DIG3 );
    variable state : state_t;
  begin
    if rising_edge(clk_in) then
      if srst_in then
        state := DIG0;
      elsif step_in then
        case state is
          when DIG0 =>
            digit <= value_in(15 downto 12);
            anodedrv <= (0=>'0', others=>'1');
            state := DIG1;
          when DIG1 =>
            digit <= value_in(11 downto 8);
            anodedrv <= (1=>'0', others=>'1');
            state := DIG2;
          when DIG2 =>
            digit <= value_in(7 downto 4);
            anodedrv <= (2=>'0', others=>'1');
            state := DIG3;
          when DIG3 =>
            digit <= value_in(3 downto 0);
            anodedrv <= (3=>'0', others=>'1');
            state := DIG0;
        end case;
      end if;
    end if;
  end process;

  -- output
  with digit select   --< g: msb, a: lsb
    segments_out <= "0001110" when x"f",
                    "0000110" when x"e",
                    "0100001" when x"d",
                    "0100111" when x"c",
                    "0000011" when x"b",
                    "0001000" when x"a",
                    "0011000" when x"9",
                    "0000000" when x"8",
                    "1111000" when x"7",
                    "0000010" when x"6",
                    "0010010" when x"5",
                    "0011001" when x"4",
                    "0110000" when x"3",
                    "0100100" when x"2",
                    "1111001" when x"1",
                    "1000000" when others; --< x"0"

  anodedrv_out <= anodedrv when not(blank_in) else (others=>'1');

end architecture;