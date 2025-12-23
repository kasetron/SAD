library ieee;
use ieee.std_logic_1164.all;

entity ripple_carry_adder is
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
end entity;

architecture structural of ripple_carry_adder is
  component full_adder
    port (
      a    : in  std_logic;
      b    : in  std_logic;
      cin  : in  std_logic;
      s    : out std_logic;
      cout : out std_logic
    );
  end component;

  -- Dichiarazione del carry interno solo se Nbit > 1
  signal cout_int : std_logic_vector(Nbit-2 downto 0);
  
begin

  -- Se Nbit = 1, usare un solo full adder senza carry interni
  g_one_bit: if Nbit = 1 generate
    i_full_adder: full_adder port map (
      a    => a_ext(0), 
      b    => b_ext(0), 
      cin  => cin_ext, 
      s    => s_ext(0), 
      cout => cout_ext
    );
  end generate;

  -- Se Nbit > 1, usare una catena di full adder
  g_multiple_bits: if Nbit > 1 generate
    first_adder: full_adder port map (
      a    => a_ext(0), 
      b    => b_ext(0), 
      cin  => cin_ext, 
      s    => s_ext(0), 
      cout => cout_int(0)
    );

    intermediate_adders: for i in 1 to Nbit-2 generate
      i_full_adder: full_adder port map (
        a    => a_ext(i), 
        b    => b_ext(i), 
        cin  => cout_int(i-1), 
        s    => s_ext(i), 
        cout => cout_int(i)
      );
    end generate;

    last_adder: full_adder port map (
      a    => a_ext(Nbit-1), 
      b    => b_ext(Nbit-1), 
      cin  => cout_int(Nbit-2), 
      s    => s_ext(Nbit-1), 
      cout => cout_ext
    );
  end generate;

end architecture;

