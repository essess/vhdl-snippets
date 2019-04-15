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
 -- simple (INC)remental (ENC)oder counter
---

entity incenc is
  generic( n   : positive;          --< counter width
           TPD : time := 0 ns );
  port( clk_in  : in  std_logic;
        srst_in : in  std_logic;
        a_in    : in  std_logic;
        b_in    : in  std_logic;
        cnt_out : out unsigned(n-1 downto 0) );
end entity;

architecture dfault of incenc is
  signal cnt : unsigned(cnt_out'range);
begin

  process(clk_in)
    subtype ab_t is std_logic_vector(1 downto 0);
    variable ab_curr, ab_prev : ab_t;
  begin
    if rising_edge(clk_in) then
      ab_curr := a_in & b_in;
      if srst_in then
        cnt     <= to_unsigned(0, cnt'length);
        ab_prev := ab_curr;
      elsif ab_prev /= ab_curr then --< a or b edge occur ?
        case ab_prev is
          when "10" => case ab_curr is
                         when "00" => cnt <= cnt -1; ab_prev := ab_curr;
                         when "11" => cnt <= cnt +1; ab_prev := ab_curr;
                         when others => null; --< NO transition
                       end case;
          when "00" => case ab_curr is
                         when "01" => cnt <= cnt -1; ab_prev := ab_curr;
                         when "10" => cnt <= cnt +1; ab_prev := ab_curr;
                         when others => null; --< NO transition
                       end case;
          when "01" => case ab_curr is
                         when "11" => cnt <= cnt -1; ab_prev := ab_curr;
                         when "00" => cnt <= cnt +1; ab_prev := ab_curr;
                         when others => null; --< NO transition
                       end case;
          when "11" => case ab_curr is
                         when "10" => cnt <= cnt -1; ab_prev := ab_curr;
                         when "01" => cnt <= cnt +1; ab_prev := ab_curr;
                         when others => null; --< NO transition
                       end case;
          when others => null;
        end case;
      end if;
    end if;
  end process;

  -- output
  cnt_out <= cnt after TPD;

end architecture;