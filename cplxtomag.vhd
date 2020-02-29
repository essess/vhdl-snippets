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
 -- (C)om(PL)e(X) (TO) (MAG)nitude^2
 --
 -- out := normalize( saturated(a_in)^2 + saturated(b_in)^2 )
 --
 -- see notes at the bottom for how this is carried out
---

entity cplxtomag is
  generic( TPD : time := 0 ns );
  port( smp_clk_in    : in  std_logic;
        srst_in       : in  std_logic;
        a_q15_in      : in  signed(15 downto 0);
        b_q15_in      : in  signed(15 downto 0);
        magsq_q15_out : out signed(15 downto 0) );
end entity;

architecture dfault of cplxtomag is

  signal a_in : signed(a_q15_in'range);
  constant MINUS_MAXA : signed(a_q15_in'range) := ('1', others=>'0');

  signal b_in : signed(a_q15_in'range);
  constant MINUS_MAXB : signed(b_q15_in'range) := ('1', others=>'0');

begin

  -- saturate -MAX to -MAX(+1):
  a_in <= (MINUS_MAXA +1) when a_q15_in = MINUS_MAXA else a_q15_in;
  b_in <= (MINUS_MAXB +1) when b_q15_in = MINUS_MAXB else b_q15_in;

  process(smp_clk_in)
    variable asq : signed((a_in'length+a_in'length)-1 downto 0);
    variable bsq : signed((b_in'length+b_in'length)-1 downto 0);
    variable magsq : signed((a_in'length+b_in'length)-1 downto 0);
  begin
    assert a_q15_in'length = b_q15_in'length;

    if rising_edge(smp_clk_in) then
      if (srst_in = '1') then
        asq   := to_signed(0, asq'length);
        bsq   := to_signed(0, bsq'length);
        magsq := to_signed(0, magsq'length);
      else
        magsq := (a_in*a_in) + (b_in*b_in); --< saturated inputs!
      end if;
      -- We've guaranteed the inputs are symmetrical around 0, so the special
      -- case result when an input is -MAX does not result. Normalization
      -- becomes a shift+resize (in trade for saturation of a rare input value)
      magsq := shift_right(magsq, magsq_q15_out'length);
      magsq_q15_out <= resize(magsq, magsq_q15_out'length) after TPD;
    end if;
  end process;

end architecture;

-- BACKGROUND:
--
-- because a twos complement reprensentation is not symetrical
-- around zero we have the special case (in fixed point math)
-- where the result needs an extra bit to properly represent the
-- full range of the signed integer portion when the Q15 value
-- is -MAX.
--
--         ** remember: QI.F * QI.F = Q(I+I).(F+F) **
--
-- therefore, if we 'saturate' the -MAX representation to -MAX(+1)
-- then we still have the Q2.30 result BUT guarantee that the
-- MSB in the integer portion will not be utilized. Normalization
-- becomes 'free' at this point.
--
-- EXAMPLE:
--
-- let's look at a Q3 and walk through the process applied above
-- for the value of a (or b) being -8 (aka the Q3 representation
-- of -MAX)
--
-- let a_in = 0b1.000 then (a_in)**2:
--
--           0b1.000 (Q1.3)  =>   0b01.000000
--         * 0b1.000 (Q1.3)  => + 0b01.000000
--         ---------         => -------------
--       0b01.000000 (Q2.6)  =>   0b10.000000
--                                  ^ this bit right here complicates
--                                  ^ follow on operations
--
-- but if we saturate to -MAX+1 then,
--
--           0b1.001 (Q1.3)  =>   0b00.110001
--         * 0b1.001 (Q1.3)  => + 0b00.110001
--         ---------         => -------------
--       0b00.110001 (Q2.6)  =>   0b01.100010
--                                  ^ guaranteed to not ovf, thus
--                                  ^ normalization is free via
--                                  ^ simple resize after shift
-- so,
--   resize(0b01.100010 >> 4) allows us to confidently use/interpret
--   the result as a properly normalized Q3 : 0b0.110
--
-- as signed integers (saturated),
--
--       (-7)  =>      +49  =>     +98
--     * (-7)  =>    + +49  =>    >> 4
--     ------  =>    -----  =>    ----
--        +49  =>      +98  =>      +6
-- (+0.765625)   (+1.53125)    (+0.750)  --> "~3/4ths of Q1.3 +ive range"
--               (| actual)    (norm'd)
--               (|   Q2.6)    (  Q1.3)
--               (+------------------------> "~3/4ths of Q2.6 +ive range"
--
--
-- YOU TRY: use the Q15 -MAX value (0x8000) to convince yourself.