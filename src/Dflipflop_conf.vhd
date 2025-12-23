library ieee;
use ieee.std_logic_1164.all;

-- Parallel D Flip-Flop with configurable number of bits (N), asynchronous reset active low, with enable

entity Dflipflop_conf is
  generic (
    Nbit : positive := 8
  );
  port (
    clk     : in  std_logic;
    resetn  : in  std_logic;
    en      : in  std_logic;
    di_ext  : in  std_logic_vector(Nbit - 1 downto 0);
    do_ext  : out std_logic_vector(Nbit - 1 downto 0)
  );
end entity;

architecture structural of Dflipflop_conf is
  component DFCE
    port (
      clk : in std_logic;
      resetn : in std_logic;
      en : in std_logic;
      di : in std_logic;
      do : out std_logic
    );
  end component;
  
begin

  g_Dflipflop: for i in 0 to Nbit-1 generate
      i_DFCE: DFCE port map (
        clk     => clk, 
        resetn  => resetn, 
        en      => en, 
        di      => di_ext(i), 
        do      => do_ext(i)
      );
  end generate;

end architecture;

