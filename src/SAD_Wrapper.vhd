library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SAD_Wrapper is
    generic (
        Nbit          : positive := 8;
        N             : positive := 512;
        NUM_IMAGES    : positive := 16;
        SAD_WIDTH     : positive := 32;
        COUNT_WIDTH   : positive := 32;
        IMG_IDX_WIDTH : positive := 16
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        en      : in  std_logic;
        pixel_A : in  std_logic_vector(Nbit-1 downto 0);
        pixel_B : in  std_logic_vector(Nbit-1 downto 0);

        sad_result        : out std_logic_vector(SAD_WIDTH-1 downto 0);
        result_valid      : out std_logic;
        result_image_idx  : out std_logic_vector(IMG_IDX_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of SAD_Wrapper is

    -- segnali interni
    signal reg_A, reg_B     : std_logic_vector(Nbit-1 downto 0);
    signal valid            : std_logic;
    signal enable           : std_logic;
    signal sadreset         : std_logic;
    signal sadout           : std_logic_vector(SAD_WIDTH-1 downto 0);
    signal image_idx        : std_logic_vector(IMG_IDX_WIDTH-1 downto 0);
    signal datain           : std_logic_vector(IMG_IDX_WIDTH-1 downto 0);
    signal resetn           : std_logic;
    signal sadreset_pulse   : std_logic;
    signal result_valid_reg : std_logic;

begin

    -- Registro di input 1: enable (da ritardare per sincronismo con pix_a e pix_b)
    dff_enable: entity work.DFCE
        port map (
            clk     => clk,
            resetn  => resetn,
            en      => '1',      -- sempre attivo
            di      => en,
            do      => enable
        );

    -- Registri di input 2,3: pix_a e pix_b
    regA: entity work.Dflipflop_conf
        generic map (
            Nbit => Nbit
        )
        port map (
            clk    => clk,
            resetn => resetn,
            en     => en,
            di_ext => pixel_A,
            do_ext => reg_A
        );

    regB: entity work.Dflipflop_conf
        generic map (
            Nbit => Nbit
        )
        port map (
            clk    => clk,
            resetn => resetn,
            en     => en,
            di_ext => pixel_B,
            do_ext => reg_B
        );


    -- Istanza del SAD
    u_sad: entity work.SAD
        generic map (
            Nbit        => Nbit,
            N           => N,
            SAD_WIDTH   => SAD_WIDTH,
            COUNT_WIDTH => COUNT_WIDTH
        )
        port map (
            clk      => clk,
            rst      => sadreset,
            enable   => enable,
            pixel_A  => reg_A,
            pixel_B  => reg_B,
            sadout   => sadout,
            valid    => valid
        );

    -- Counter immagini
    u_image_ctr: entity work.counter
        generic map (
            Nbit => IMG_IDX_WIDTH
        )
        port map (
            di     => datain,
            clk    => clk,
            resetn => resetn,
            do     => image_idx
        );

    resetn <= not rst;

    -- datain fornisce impulso in ingresso al contatore solo quando valid->1, per contare immagini
    datain   <= (IMG_IDX_WIDTH-1 downto 1 => '0') & result_valid_reg;

    sadreset <= rst or sadreset_pulse; -- sad resettato al termine di ogni immagine o globalmente se vi è reset esterno

    -- FSM gestione sequenza immagini
    process(clk, rst)
    begin
        if rst = '1' then
            sad_result         <= (others => '0');
            result_valid_reg   <= '0';
            sadreset_pulse     <= '0';

        elsif rising_edge(clk) then

            -- Default: impulso nullo
            sadreset_pulse <= '0';

            -- Quando SAD segnala che ha finito, congela il risultato
            if valid = '1' then
                sad_result   <= sadout;
                result_valid_reg <= '1';

                if to_integer(unsigned(image_idx)) < NUM_IMAGES then
                    sadreset_pulse   <= '1';  -- genera reset per prossimo SAD
                else
                    result_valid_reg <= '0';
                end if;
            else
                result_valid_reg <= '0';
            end if;
        end if;
    end process;

    -- Uscite
    result_valid     <= result_valid_reg;
    result_image_idx <= image_idx;

end architecture;

