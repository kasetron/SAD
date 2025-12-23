library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SAD_tb is
end entity;

architecture beh of SAD_tb is

    -- Costanti di test
    constant clk_period  : time     := 100 ns;
    constant Nbit        : positive := 8;
    constant N           : positive := 4;
    constant SAD_WIDTH   : positive := 16;
    constant COUNT_WIDTH : positive := 6;

    component SAD is
        generic (
            Nbit          : positive := 8;
            N             : positive := 512;
            SAD_WIDTH     : positive := 32;
            COUNT_WIDTH   : positive := 32
        );
        port (
            clk      : in  std_logic;
            rst      : in  std_logic;
            enable   : in  std_logic;
            pixel_A  : in  std_logic_vector(Nbit-1 downto 0);
            pixel_B  : in  std_logic_vector(Nbit-1 downto 0);
            sadout   : out std_logic_vector(SAD_WIDTH-1 downto 0);
            valid    : out std_logic
        );
    end component;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal enable   : std_logic := '0';
    signal pixel_A  : std_logic_vector(Nbit-1 downto 0) := (others => '0');
    signal pixel_B  : std_logic_vector(Nbit-1 downto 0) := (others => '0');
    signal sadout   : std_logic_vector(SAD_WIDTH-1 downto 0);
    signal valid    : std_logic := '0';
    signal testing  : boolean := true;

    -- Stimoli immagine
    type image_array is array (0 to N*N-1) of std_logic_vector(Nbit-1 downto 0);
    signal imgA, imgB : image_array;

    signal expected_sad : integer := 0;
    signal computed_sad : integer := 0;

begin

    clk <= not clk after clk_period/2 when testing else '0';

    DUT: SAD
        generic map (
            Nbit        => Nbit,
            N           => N,
            SAD_WIDTH   => SAD_WIDTH,
            COUNT_WIDTH => COUNT_WIDTH
        )
        port map (
            clk     => clk,
            rst     => rst,
            enable  => enable,
            pixel_A => pixel_A,
            pixel_B => pixel_B,
            sadout  => sadout,
            valid   => valid
        );

    STIMULI : process
            variable i : integer;                    -- Serve per loop con cui fornisco pixel in ingresso
            variable expected_total : integer := 0;  -- Serve per tenere traccia del sad atteso
    begin

        -- Inizializzazione immagini di esempio
        for i in 0 to N*N - 1 loop
            imgA(i) <= std_logic_vector(to_unsigned(i*10, Nbit));      -- 0, 10, 20, ...
            imgB(i) <= std_logic_vector(to_unsigned(i*10 + 5, Nbit));  -- 5, 15, 25, ...
            expected_total := expected_total + 5;  -- diff = 5 per ogni pixel
        end loop;

        rst <= '1';
        wait for 300 ns;
        rst <= '0';
        wait for 200 ns;

        enable <= '1';

        wait until rising_edge(clk);

        -- Invia pixel uno per uno
        for i in 0 to N*N - 1 loop
            pixel_A <= imgA(i);
            pixel_B <= imgB(i);
            wait until rising_edge(clk);
        end loop;

        enable <= '0';
        pixel_A <= (others => '0');
        pixel_B <= (others => '0');

        -- Attendi segnale valid
        wait until valid = '1';
        wait for 200 ns;
        wait until rising_edge(clk);

        -- Conversione del risultato
        computed_sad <= to_integer(unsigned(sadout));
        expected_sad <= expected_total;
        wait until rising_edge(clk);
        report "SAD calcolato: " & integer'image(computed_sad);
        report "SAD atteso:    " & integer'image(expected_sad);

        assert computed_sad = expected_sad
            report "Errore: SAD diverso da atteso!" severity error;

        rst <= '1';
        wait for 300 ns;
        rst <= '0';
        wait for 200 ns;

        enable <= '1';

        wait until rising_edge(clk);

        -- test reset e enable mid-stream (attenzione necessario N>sqrt(14))
        for i in 0 to N*N - 13 loop
            pixel_A <= imgA(i);
            pixel_B <= imgB(i);
            wait until rising_edge(clk);
        end loop;
        rst <= '1';
        pixel_A <= imgA(N*N - 12);
        pixel_B <= imgB(N*N - 12);
        wait until rising_edge(clk);
        rst <= '0';
        for i in N*N - 11 to N*N - 6 loop
            pixel_A <= imgA(i);
            pixel_B <= imgB(i);
            wait until rising_edge(clk);
        end loop;
        enable <= '0';
        for i in N*N - 5 to N*N - 3 loop
            pixel_A <= imgA(i);
            pixel_B <= imgB(i);
            wait until rising_edge(clk);
        end loop;
        enable <= '1';
        for i in N*N - 2 to N*N - 1 loop
            pixel_A <= imgA(i);
            pixel_B <= imgB(i);
            wait until rising_edge(clk);
        end loop;

        wait for 1000 ns;
        enable <= '0';

        rst <= '1';
        wait for 300 ns;
        rst <= '0';
        wait for 200 ns;
        enable <= '1';

        wait until rising_edge(clk);

        -- Invia pixel uno per uno
        for i in 0 to N*N - 1 loop
            pixel_A <= std_logic_vector(to_unsigned(0, Nbit));
            pixel_B <= std_logic_vector(to_unsigned(255, Nbit));
            wait until rising_edge(clk);
        end loop;

        enable <= '0';
        pixel_A <= (others => '0');
        pixel_B <= (others => '0');

        -- Attendi segnale valid
        wait until valid = '1';
        wait for 200 ns;
        wait until rising_edge(clk);

        -- Conversione del risultato
        computed_sad <= to_integer(unsigned(sadout));
        expected_sad <= expected_total;
        wait until rising_edge(clk);
        report "SAD calcolato: " & integer'image(computed_sad);
        report "SAD atteso:    " & integer'image(expected_sad);
        testing <= false;

        assert computed_sad = expected_sad
            report "Errore: SAD diverso da atteso!" severity error;

    end process;

end architecture;
