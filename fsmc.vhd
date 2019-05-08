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
 -- (TOP) level implementation of psram-intf
 --
 -- read/write byte order:
 --    BYTE_0   ----->   BYTE_3
 --    LSByte            MSByte
 --
 -- The bus has some weird rules and luckily we're in an FPGA
 -- and can adapt :
 --
 --    1) all accesses can be word/halfword/byte (32b/16b/8b)
 --    2) all accesses may be aligned on word/halfword/byte boundaries
 --
 -- due to some odd burst splitting, there are further rules:
 --
 --    3) 32b writes WILL SPLIT if not aligned to word boundaries
 --       and therefore not atomic (could be important for dpram)
 --       (byte alignment results in 3 accesses minimum!)
 --    4) 16b reads  WILL SPLIT if not aligned to halfword boundaries
 --       and therefore not atomic (could be important for dpram)
 --       (byte alignment results in 2 accesses minimum!)
 --
 -- therefore:
 --
 --    5) align all 32b access to word boundaries for highest
 --       performance and to ensure atomic rd/wr scenarios
 --    6) align all 16b access to halfword boundaries for highest
 --       performance and to ensure atomic rd/wr scenarios
 --    7) 8b reads have horrible throughput, just do 16b aligned reads minimum
 --    8) writes require 2 less clocks than reads
 --       (reads have a mandatory +2 clk latency)
 --
 -- and only requires:
 --
 --    ad_io[7:0]  +8
 --    noe_in      +1
 --    nwe_in      +1
 --    nadv_in     +1
 --    ne_in[1]    +1
 --              ------
 --                12     total lines for a   --> pretty good!
 --                       256 byte window
---

entity top is
  generic( TPD : time := 0 ns );
  port( clk_in    : in    std_logic;
        arstn_in  : in    std_logic;
        ad_io     : inout std_logic_vector(7 downto 0);
        noe_in    : in    std_logic;
        nwe_in    : in    std_logic;
        nadv_in   : in    std_logic;
        ne_in     : in    std_logic_vector(1 downto 1);
        led_out   : out   std_logic_vector(7 downto 0) );
end entity;

architecture dfault of top is

  component ramdq is
      port (
          Clock: in  std_logic;
          ClockEn: in  std_logic;
          Reset: in  std_logic;
          WE: in  std_logic;
          Address: in  std_logic_vector(7 downto 0);
          Data: in  std_logic_vector(7 downto 0);
          Q: out  std_logic_vector(7 downto 0));
  end component;


  signal a : unsigned(ad_io'range);
  signal q : std_logic_vector(ad_io'range);
  signal arst, clkenb : std_logic;

begin
  led_out(7 downto 0) <= (others=>'1'); --< off
  arst <= not(arstn_in);

  shim: process(clk_in, arst)
    type state_t is ( IDLE,
                      fromFSMC_LAT1, fromFSMC_LAT2, fromFSMC_BYTE0, fromFSMC_BYTE1, fromFSMC_BYTE2, fromFSMC_BYTE3,
                        toFSMC_LAT1,                  toFSMC_BYTE0,   toFSMC_BYTE1,   toFSMC_BYTE2,   toFSMC_BYTE3 );
    variable state : state_t := IDLE;
  begin
    if arst then
      clkenb <= '0';
      a <= unsigned(ad_io);
      state := IDLE;
    elsif rising_edge(clk_in) then
      clkenb <= '0';
      ---
       -- nadv asserted has priority over all,
       -- >>> immediate restart of cycle <<<
      ---
      if not(nadv_in) and not(ne_in(1)) then
        a <= unsigned(ad_io);     --< capture address
        if nwe_in then
          --clkenb <= '1';
          state := toFSMC_LAT1;   --< FSMC <= mem
        else
          state := fromFSMC_LAT1; --<  mem <= FSMC
        end if;
      else
      ---
       -- else, likely in the middle of an ongoing rd/wr cycle
      ---
        case state is
          ---------------------------------------------------
          -- rd cycle
          ---------------------------------------------------
          when toFSMC_LAT1 =>
            clkenb <= '1';  --< begin fetch byte0
            state := toFSMC_BYTE0;
          when toFSMC_BYTE0 =>
            clkenb <= '1';
            a <= a +1;      --< begin fetch byte1
            state := toFSMC_BYTE1;
          when toFSMC_BYTE1 =>
            clkenb <= '1';
            a <= a +1;      --< begin fetch byte2
            state := toFSMC_BYTE2;
          when toFSMC_BYTE2 =>
            clkenb <= '1';
            a <= a +1;      --< begin fetch byte3
            state := toFSMC_BYTE3;
          when toFSMC_BYTE3 =>
            state := IDLE;  --< (this is the widest the FSMC bursts)
          ---------------------------------------------------
          -- wr cycle
          ---------------------------------------------------
          when fromFSMC_LAT1 =>
            state := fromFSMC_LAT2;
          when fromFSMC_LAT2 =>
            clkenb <= '1';  --< FSMC drives byte0 on fe
            state := fromFSMC_BYTE0;
          when fromFSMC_BYTE0 =>
            clkenb <= '1';  --< FSMC drives byte1 on fe
            a <= a +1;      --< ... and a++
            state := fromFSMC_BYTE1;
          when fromFSMC_BYTE1 =>
            clkenb <= '1';  --< FSMC drives byte1 on fe
            a <= a +1;      --< ... and a++
            state := fromFSMC_BYTE2;
          when fromFSMC_BYTE2 =>
            clkenb <= '1';  --< FSMC drives byte1 on fe
            a <= a +1;      --< ... and a++
            state := fromFSMC_BYTE3;
          when fromFSMC_BYTE3 =>
            state := IDLE;  --< (this is the widest the FSMC bursts)
          ---------------------------------------------------
          when others =>    --< IDLE
        end case;
      end if;
    end if;
  end process;

  ad_io <= q after TPD when (not(noe_in) and not(ne_in(1)))
                       else (others=>'Z');

  ram: ramdq
    port map( Clock   => clk_in,
              ClockEn => clkenb,
              Reset   => arst,
              WE      => not(nwe_in),
              Address => std_logic_vector(a),
              Data    => ad_io,
              Q       => q );

end architecture;