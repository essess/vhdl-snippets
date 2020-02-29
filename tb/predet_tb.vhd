---
 -- Copyright (c) 2020 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all;

entity predet_tb is
  generic( tclk : time := 10 ns;
           TPD  : time := 2  ns );
end entity;

architecture dfault of predet_tb is

  component predet is
    generic( TPD : time := 0 ns );
    port( smp_clk_in   : in  std_logic;
          srst_in      : in  std_logic;
          smp_in       : in  unsigned(15 downto 0);
          threshold_in : in  unsigned(15 downto 0);
          smp_out      : out unsigned(15 downto 0);
          valid_out    : out std_logic );
  end component;

  constant WAITCLK : integer := 2;
  signal   clkcnt  : natural := 0;
  signal   clk     : std_logic;

  signal srst, valid                : std_logic;
  signal smp_in, smp_out, threshold : unsigned(15 downto 0);

  signal bos_toggle,chk_toggle : std_logic;

begin

  dut : predet
    generic map( TPD => TPD )
    port map( smp_clk_in   => clk,
              srst_in      => srst,
              smp_in       => smp_in,
              threshold_in => threshold,
              smp_out      => smp_out,
              valid_out    => valid );

  tb : process
  begin

    wait for TPD;
    srst <= '1';
    smp_in <= to_unsigned(16#1FFF#, smp_in'length);
    threshold <= to_unsigned(16#7FFF#, threshold'length);
    bos_toggle <= '0'; --< toggle on beginning of symbol
    chk_toggle <= '0'; --< toggle on assert performed

    wait until rising_edge(clk); wait for TPD;
    srst <= '0';
    smp_in <= to_unsigned(16#2FFF#, smp_in'length);

    wait until rising_edge(clk); wait for TPD;
    chk_toggle <= not chk_toggle;
    assert smp_in = smp_out report "FAIL0.0 : initial conditions";

    -- test --
    -- check that threshold is working. Internal DUT signal, so do
    -- inspection of waveform manually

    wait until rising_edge(clk); wait for TPD;
    smp_in    <= to_unsigned(16#2FFF#, smp_in'length);
    wait until rising_edge(clk); wait for TPD;
    smp_in    <= to_unsigned(16#3FFF#, smp_in'length);
    wait until rising_edge(clk); wait for TPD;
    smp_in    <= to_unsigned(16#4FFF#, smp_in'length);
    wait until rising_edge(clk); wait for TPD;
    smp_in    <= to_unsigned(16#5FFF#, smp_in'length);
    wait until rising_edge(clk); wait for TPD;
    smp_in    <= to_unsigned(16#6FFF#, smp_in'length);
    wait until rising_edge(clk); wait for TPD;
    smp_in    <= to_unsigned(16#7FFF#, smp_in'length);
    wait until rising_edge(clk); wait for TPD;
    smp_in    <= to_unsigned(16#8FFF#, smp_in'length);
    wait until rising_edge(clk); wait for TPD;
    smp_in    <= to_unsigned(16#9FFF#, smp_in'length);
    wait until rising_edge(clk); wait for TPD;
    smp_in    <= to_unsigned(16#AFFF#, smp_in'length);
    wait until rising_edge(clk); wait for TPD;
    smp_in    <= to_unsigned(16#BFFF#, smp_in'length);
    wait until rising_edge(clk); wait for TPD;
    smp_in    <= to_unsigned(16#CFFF#, smp_in'length);
    wait until rising_edge(clk); wait for TPD;
    smp_in    <= to_unsigned(16#DFFF#, smp_in'length);
    wait until rising_edge(clk); wait for TPD;
    smp_in    <= to_unsigned(16#EFFF#, smp_in'length);
    wait until rising_edge(clk); wait for TPD;
    smp_in    <= to_unsigned(16#FFFF#, smp_in'length);

    -- test --
    -- start detection of best case sequence
    -- inspection of waveform manually
    wait until rising_edge(clk); wait for TPD;
    srst      <= '1';
    smp_in    <= to_unsigned(16#0000#, smp_in'length);
    threshold <= to_unsigned(16#7FFF#, threshold'length);

    wait until rising_edge(clk); wait for TPD;
    srst <= '0';
    chk_toggle <= not chk_toggle;
    assert smp_out = smp_in report "FAIL1.0 : initial conditions";
    assert valid   = '0'    report "FAIL1.1 : initial conditions";


    --< begin sequence
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1---_----_----_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "11--_----_----_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "110-_----_----_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_----_----_----_----_----_----_----"
    -- end of first symbol >> '1-------'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1100_1---_----_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1100_11--_----_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_110-_----_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_----_----_----_----_----_----"
    -- end of next symbol >> '11------'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0---_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_00--_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_000-_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_----_----_----_----_----"
    -- end of next symbol >> '11L-----'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0---_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_00--_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1100_1100_0000_001-_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1100_1100_0000_0011_----_----_----_----"
    -- end of next symbol >> '11L0----'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0---_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_00--_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1100_1100_0000_0011_001-_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1100_1100_0000_0011_0011_----_----_----"
    -- end of next symbol >> '11L00---'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0---_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_00--_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_000-_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_----_----"
    -- end of next symbol >> '11L00L--'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_0---_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_00--_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_000-_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_0000_----"
    -- end of next symbol >> '11L00LL-'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#1000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_0000_0---"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_0000_00--"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#1000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_0000_000-"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_0000_0000"
    -- end of PREAMBLE >> '11L00LLL'

    ---
    ---
    ---

    --< begin sequence
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1---_----_----_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "11--_----_----_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "110-_----_----_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_----_----_----_----_----_----_----"
    -- end of first symbol >> '1-------'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1100_1---_----_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1100_11--_----_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_110-_----_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_----_----_----_----_----_----"
    -- end of next symbol >> '11------'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0---_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_00--_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_000-_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_----_----_----_----_----"
    -- end of next symbol >> '11L-----'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0---_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_00--_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1100_1100_0000_001-_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1100_1100_0000_0011_----_----_----_----"
    -- end of next symbol >> '11L0----'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0---_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_00--_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1100_1100_0000_0011_001-_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1100_1100_0000_0011_0011_----_----_----"
    -- end of next symbol >> '11L00---'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0---_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_00--_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_000-_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_----_----"
    -- end of next symbol >> '11L00L--'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_0---_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_00--_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_000-_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_0000_----"
    -- end of next symbol >> '11L00LL-'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#1000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_0000_0---"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_0000_00--"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#1000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_0000_000-"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_0000_0000"
    -- end of PREAMBLE >> '11L00LLL'

    ---
    ---
    ---

    --< begin sequence
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1---_----_----_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "11--_----_----_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "110-_----_----_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_----_----_----_----_----_----_----"
    -- end of first symbol >> '1-------'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1100_1---_----_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1100_11--_----_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_110-_----_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_----_----_----_----_----_----"
    -- end of next symbol >> '11------'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0---_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_00--_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_000-_----_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_----_----_----_----_----"
    -- end of next symbol >> '11L-----'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0---_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_00--_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1100_1100_0000_001-_----_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1100_1100_0000_0011_----_----_----_----"
    -- end of next symbol >> '11L0----'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0---_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_00--_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1100_1100_0000_0011_001-_----_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#F000#, smp_in'length);  --< "1100_1100_0000_0011_0011_----_----_----"
    -- end of next symbol >> '11L00---'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0---_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_00--_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_000-_----_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_----_----"
    -- end of next symbol >> '11L00L--'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_0---_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_00--_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_000-_----"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_0000_----"
    -- end of next symbol >> '11L00LL-'

    --
    wait until rising_edge(clk); wait for TPD;
    bos_toggle <= not bos_toggle;
    smp_in <= to_unsigned(16#1000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_0000_0---"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_0000_00--"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#1000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_0000_000-"

    wait until rising_edge(clk); wait for TPD;
    smp_in <= to_unsigned(16#0000#, smp_in'length);  --< "1100_1100_0000_0011_0011_0000_0000_0000"
    -- end of PREAMBLE >> '11L00LLL'

    -- test --
    -- test --
    -- test --
    -- test --
    -- test --

    wait for 4*tclk;
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
