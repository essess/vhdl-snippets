-- testbench
library ieee, std;
use ieee.std_logic_1164.all, std.env.all;

entity sr_tb is
-- empty
  generic(tclk:time := 10 ns);
end sr_tb;

architecture dfault of sr_tb is

  component sr is
    generic( width : integer range 2 to integer'high );
    port( d_in           : in  std_logic;
          rst_in, clk_in : in  std_logic;
          q_out          : out std_logic_vector(width-1 downto 0) );
  end component;

  constant width : integer := 4;
  signal d_in  : std_logic;
  signal rst_in, clk_in : std_logic;
  signal q_out : std_logic_vector(width-1 downto 0);

  constant all_ones  : std_logic_vector(width-1 downto 0) := (others=>'1');
  constant all_zeros : std_logic_vector(width-1 downto 0) := (others=>'0');

begin

  dut : sr
    generic map( width => width )
    port map( d_in => d_in,
              rst_in => rst_in,
              clk_in => clk_in,
              q_out => q_out );

  tb : process
  begin
     wait for 1*tclk;

    -----------
    -- everything is synchronous to clk_in
    -----------

    rst_in <= '1';
    clk_in <= '0';
    d_in   <= '1'; wait for 1*tclk;
    clk_in <= '1'; wait for 1*tclk;
    assert (q_out = all_ones) report "FAIL: rst_in all_ones" severity failure;

    rst_in <= '1';
    clk_in <= '0';
    d_in   <= '0'; wait for 1*tclk;
    clk_in <= '1'; wait for 1*tclk;
    assert (q_out = all_zeros) report "FAIL: rst_in all_zeros" severity failure;

    -----------
    -- shift in "1100" and check along the way
    rst_in <= '0';
    clk_in <= '0';
    d_in   <= '1'; wait for 1*tclk;
    clk_in <= '1'; wait for 1*tclk;
    assert (q_out = "0001") report "FAIL: shift0" severity failure;

    clk_in <= '0';
    d_in   <= '1'; wait for 1*tclk;
    clk_in <= '1'; wait for 1*tclk;
    assert (q_out = "0011") report "FAIL: shift1" severity failure;

    clk_in <= '0';
    d_in   <= '0'; wait for 1*tclk;
    clk_in <= '1'; wait for 1*tclk;
    assert (q_out = "0110") report "FAIL: shift2" severity failure;

    clk_in <= '0';
    d_in   <= '0'; wait for 1*tclk;
    clk_in <= '1'; wait for 1*tclk;
    assert (q_out = "1100") report "FAIL: shift3" severity failure;
    -----------

    wait; stop;
  end process tb;

end architecture;
