---
 -- Copyright (c) 2019 Sean Stasiak. All rights reserved.
 -- Developed by: Sean Stasiak <sstasiak@protonmail.com>
 -- Refer to license terms in license.txt; In the absence of such a file,
 -- contact me at the above email address and I can provide you with one.
---

library ieee;
use ieee.std_logic_1164.all,
    ieee.numeric_std.all;

entity top_tb is
  generic( tclk : time := 10 ns;
           TPD  : time := 2  ns );
end entity;

architecture dfault of top_tb is

  component top is
    generic( TPD : time := 0 ns );
    port( clk_in    : in    std_logic;
          arstn_in  : in    std_logic;
          ad_io     : inout std_logic_vector(7 downto 0);
          noe_in    : in    std_logic;
          nwe_in    : in    std_logic;
          nadv_in   : in    std_logic;
          ne_in     : in    std_logic_vector(1 downto 1);
          led_out   : out   std_logic_vector(7 downto 0) );
  end component;

  constant WAITCLK : integer := 2;
  signal   clkcnt  : natural := 0;
  signal   clk     : std_logic;

  signal arstn, noe, nwe, nadv : std_logic;
  signal ad : std_logic_vector(7 downto 0);
  signal ne : std_logic_vector(1 downto 1);
  signal led : std_logic_vector(7 downto 0);

begin

  dut : top
    generic map( TPD => TPD )
    port map( clk_in   => clk,
              arstn_in => arstn,
              ad_io    => ad,
              noe_in   => noe,
              nwe_in   => nwe,
              nadv_in  => nadv,
              ne_in(1) => ne(1),
              led_out  => led );

  tb : process
  begin

    wait for 1*tclk;
    arstn <= '0';
    wait until clk = '1';
    wait for (1*tclk)/4;
    arstn <= '1';

    wait until clkcnt = 4;

    -- test for best case alignments and general functionality
    --
    -- TODO: handle ->
      -- // wr
      -- *(uint32_t*)0x60000010 = (uint32_t)0x44556677;  // 32b align 4 test
      -- *(uint32_t*)0x60000012 = (uint32_t)0x44556677;  //     align 2 test
      -- *(uint32_t*)0x60000021 = (uint32_t)0x44556677;  //     align 1 test
      -- *(uint16_t*)0x60000010 = (uint16_t)0x6677;      // 16b align 4 test
      -- *(uint16_t*)0x60000012 = (uint16_t)0x6677;      //     align 2 test
      -- *(uint16_t*)0x60000021 = (uint16_t)0x6677;      //     align 1 test
      -- *(uint8_t*)0x60000010 =  (uint8_t)0x77;         //  8b align 4 test
      -- *(uint8_t*)0x60000012 =  (uint8_t)0x77;         //     align 2 test
      -- *(uint8_t*)0x60000021 =  (uint8_t)0x77;         //     align 1 test

      -- // followed by rd
      -- val = (uint32_t)(*(uint32_t*)0x60000010);       // 32b align 4 test
      -- val = (uint32_t)(*(uint32_t*)0x60000012);       //     align 2 test
      -- val = (uint32_t)(*(uint32_t*)0x60000021);       //     align 1 test
      -- val = (uint16_t)(*(uint16_t*)0x60000010);       // 16b align 4 test
      -- val = (uint16_t)(*(uint16_t*)0x60000012);       //     align 2 test
      -- val = (uint16_t)(*(uint16_t*)0x60000021);       //     align 1 test
      -- val =   (uint8_t)(*(uint8_t*)0x60000010);       //  8b align 4 test
      -- val =   (uint8_t)(*(uint8_t*)0x60000012);       //     align 2 test
      -- val =   (uint8_t)(*(uint8_t*)0x60000021);       //     align 1 test

    wait until clkcnt = 55;
    report "DONE"; std.env.stop;
  end process;

  memrw : process
    constant pause_clks : integer := 4;
    variable addr : integer;
  begin
    ne(1)    <= '1';
    nwe      <= '1';
    noe      <= '1';
    nadv     <= '1';
    wait until clkcnt = 4;
    loop
      addr := 0;
      -- write cycle
      wait until clk = '0';
      ne(1) <= '0';
      nwe   <= '0';
      noe   <= '1';
      nadv  <= '0';
      wait for TPD;
      ad    <= std_logic_vector(to_unsigned(addr,ad'length));
      wait until falling_edge(clk);
      nadv <= '1';
      wait for TPD;
      ad   <= x"ZZ";
      wait until falling_edge(clk);
      wait until rising_edge(clk);
      noe  <= '1';

      wait for 6*tclk;
      wait until falling_edge(clk);

      noe   <= '1';
      nwe   <= '1';
      ne(1) <= '1';
      addr := addr +4;
      wait for pause_clks*tclk;

      -- read cycle
      wait until clk = '0';
      ne(1) <= '0';
      nwe   <= '1';
      noe   <= '1';
      nadv  <= '0';
      wait for TPD;
      ad    <= std_logic_vector(to_unsigned(addr,ad'length));
      wait until falling_edge(clk);
      nadv <= '1';
      wait for TPD;
      ad   <= x"ZZ";
      wait until falling_edge(clk);
      wait until rising_edge(clk);
      noe  <= '0';

      wait for 6*tclk;
      wait until falling_edge(clk);

      noe   <= '1';
      nwe   <= '1';
      ne(1) <= '1';
      addr := addr +4;
      wait for pause_clks*tclk;
    end loop;
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
