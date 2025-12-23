library ieee;
use ieee.std_logic_1164.all;

entity counter is
  generic (
    Nbit : positive := 8
  );
  port (
    di     : in  std_logic_vector(Nbit - 1 downto 0);
    clk    : in  std_logic;
    resetn : in  std_logic;
    do     : out std_logic_vector(Nbit - 1 downto 0)
  );
end entity;

architecture structural of counter is
  component ripple_carry_adder
    generic (
      Nbit : positive := 8
    );
    port (
    a_ext    : in  std_logic_vector(Nbit - 1 downto 0);
    b_ext    : in  std_logic_vector(Nbit - 1 downto 0);
    cin_ext  : in  std_logic;
    s_ext    : out std_logic_vector(Nbit - 1 downto 0);
    cout_ext : out std_logic
    );
  end component;

  component Dflipflop_conf
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
  end component;

  signal current_count : std_logic_vector(Nbit - 1 downto 0);
  signal next_count    : std_logic_vector(Nbit - 1 downto 0);
  
begin
  
  -- Ripple carry adder per calcolare il nuovo valore del contatore
  adder_inst: ripple_carry_adder
    generic map (
      Nbit => Nbit
    )
    port map (
      a_ext    => current_count,
      b_ext    => di,
      cin_ext  => '0',
      s_ext    => next_count,
      cout_ext => open
    );

  -- Flip-flop per memorizzare il valore del contatore
  dff_inst: Dflipflop_conf
    generic map (
      Nbit => Nbit
    )
    port map (
      clk     => clk,
      resetn  => resetn,
      en      => '1',
      di_ext  => next_count,
      do_ext  => current_count
    );

  -- Output del contatore
  do <= current_count;

end architecture;

