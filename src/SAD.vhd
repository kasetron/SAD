library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SAD is
    generic (
        Nbit          : positive := 8;       -- Bit per pixel
        N             : positive := 512;     -- Dimensione immagine NxN
        SAD_WIDTH     : positive := 32;      -- Bit per accumulatore SAD, max = (2^Nbit-1)*N*N
        COUNT_WIDTH   : positive := 32       -- Bit per contatore pixel, deve arrivare a: N*N
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
end entity;


architecture beh of SAD is

    signal diff         : std_logic_vector(Nbit-1 downto 0);
    signal sad_acc      : std_logic_vector(SAD_WIDTH-1 downto 0);
    signal next_sad     : std_logic_vector(SAD_WIDTH-1 downto 0);
    signal diff_ext     : std_logic_vector(SAD_WIDTH-1 downto 0);
    signal pixel_count  : std_logic_vector(COUNT_WIDTH-1 downto 0);
    signal datain       : std_logic_vector(COUNT_WIDTH-1 downto 0);
    signal done         : std_logic;
    signal resetn       : std_logic;

    constant MAX_PIXELS : positive := N * N;

begin

    resetn <= not rst;

    diff_ext <= (SAD_WIDTH-1 downto Nbit => '0') & diff;    -- estensione diff da Nbit a SAD_WIDTH  
    datain   <= (COUNT_WIDTH-1 downto 1 => '0') & enable;   -- datain fornisce 1 in ingresso al contatore con enable attivo (avvia incremento)

    -- Calcolo differenza assoluta
    p_diff: process(pixel_A, pixel_B)
    begin
        if unsigned(pixel_A) > unsigned(pixel_B) then
            diff <= std_logic_vector(unsigned(pixel_A) - unsigned(pixel_B));
        else
            diff <= std_logic_vector(unsigned(pixel_B) - unsigned(pixel_A));
        end if;
    end process;

    -- Somma cumulativa (sad_acc + diff)
    RCA: entity work.ripple_carry_adder
        generic map (
            Nbit => SAD_WIDTH
        )
        port map (
            a_ext    => sad_acc,
            b_ext    => diff_ext,
            cin_ext  => '0',
            s_ext    => next_sad,
            cout_ext => open
        );

    -- Registro per accumulatore SAD
    sad_reg: entity work.Dflipflop_conf
        generic map (
            Nbit => SAD_WIDTH
        )
        port map (
            clk    => clk,
            resetn => resetn,
            en     => enable,
            di_ext => next_sad,
            do_ext => sad_acc
        );

    -- Contatore pixel (incrementa se enable=1)
    pixel_ctr: entity work.counter
        generic map (
            Nbit => COUNT_WIDTH
        )
        port map (
            di     => datain,
            clk    => clk,
            resetn => resetn,
            do     => pixel_count
        );

    -- Generazione del segnale "done"
    done <= '1' when unsigned(pixel_count) = to_unsigned(MAX_PIXELS, COUNT_WIDTH) else '0';

    -- Logica del segnale "valid"
    p_FSM: process(clk, rst)
    begin
        if rst = '1' then
            valid   <= '0';
        elsif rising_edge(clk) then
            if done = '1' then
                valid <= '1';
            end if;
        end if;
    end process;

    -- Output SAD
    sadout <= sad_acc;


end architecture;

