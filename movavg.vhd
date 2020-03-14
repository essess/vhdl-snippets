---
 -- Copyright (c) 2020 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all,
    ieee.math_real.all;

---
 -- A simple (MOV)ing (AV)era(G)e
---

entity movavg is
  generic( LENGTH : positive;
           TPD : time := 0 ns );
  port( smp_clk_in   : in  std_logic;
        srst_in      : in  std_logic;
        scale_q15_in : in  signed(15 downto 0);
        smp_q15_in   : in  signed(15 downto 0);
        smp_q15_out  : out signed(15 downto 0);
        avg_q15_out  : out signed(15 downto 0) );
end entity;

architecture dfault of movavg is

begin

  process(smp_clk_in)

    constant LENBITS : natural := integer(ceil(log2(real(LENGTH))));
    variable acc : signed((smp_q15_in'left+LENBITS) downto 0);
    variable avg : signed((acc'length+scale_q15_in'length-1) downto 0);

    type smpary_t is array (LENGTH-1 downto 0) of signed(smp_q15_in'range);
    variable smps : smpary_t; --< 'samples' : 'sample array type'

  begin
    if rising_edge(smp_clk_in) then
      acc := to_signed(0, acc'length);
      if(srst_in = '1') then
        smps := (others=>(others=>'0'));
        avg  := (others=>'0');
      else
        smps := smp_q15_in & smps(LENGTH-1 downto 1);
        for i in smps'range loop                        --< sum
          acc := acc + resize(smps(i), acc'length);     --< sign extended via resize
        end loop;
        avg := acc * scale_q15_in;                      --< scale
      end if;
      avg := shift_right(avg, (acc'length-1)-LENBITS);  --< normalize
      avg_q15_out <= resize(avg, avg_q15_out'length) after TPD;
    end if;
  end process;

  -- passthru samples unconditionally
  smp_q15_out <= smp_q15_in after TPD when rising_edge(smp_clk_in);

end architecture;

-- BACKGROUND:
--
-- this is nothing more than a FIR filter where we do a single scaling
-- multiply on the accumulated value. to not clutter the above, lets
-- have a little discussion down here about the decisions above,
--
--           ** remember: QI.F * QI.F = Q(I+I).(F+F) **
--
-- to keep as much precision as possible throughout the calc, we need
-- to range the accumulator appropriately. our sample inputs are Q1.15
-- and depending on the number of taps requested (via LENGTH) we need
-- to determine how many bits to 'tack on' to prevent overflow (see the
-- LENBITS constant).
--
-- therefore, our accumulator representation is:
--   Q1.15 * Q(LENBITS).0 => Q(1+LENBITS).15
--
-- the scaling op results in our representation of the average:
--   Q(1+LENBITS).15 *  Q1.15  => Q(2+LENBITS).30
--   [ accumulator ] * [scale] => [   average   ]
--
-- as the final normalization step LENBITS needs backed out!
--   Q(2+LENBITS).30 >> (1+LENBITS+15)-1-LENBITS) => Q1.15
--   [   average   ]
--
-- but really, the shift results in a Q((2+LENBITS+30)-15).15 and the
-- Q1.15 (least significant portion) is output as the average.
--
-- EXAMPLE:
--
-- if, LENGTH := 4, then LENBITS := 2
--   therefore, acc is a Q3.15
--   and,       avg is a Q4.30
--   and,        >> is 18-1-2
--
-- YOU TRY:
--
-- pass a step through the filter using the above LENGTH of 4 and
-- scale of 1/LENGTH. do it by hand.
