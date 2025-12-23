library ieee;
use ieee.std_logic_1164.all;

entity DFCE is
  port (
    clk : in std_logic;
    resetn : in std_logic;
    en : in std_logic;
    di : in std_logic;
    do : out std_logic
  );
end entity;

architecture rtl of DFCE is
  -- internal signals
  signal di_s : std_logic;
  signal do_s : std_logic;

begin

  p_DFCE: process(clk, resetn)
  begin
    if resetn = '0' then
      do_s <= '0';
    elsif rising_edge(clk) then
      do_s <= di_s;
    end if;
  end process;
  
  di_s <= di when en = '1' else do_s;
  do <= do_s;

end architecture;