library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils_pkg.all;

entity SAD_Wrapper_tb_large is
end entity;

architecture sim of SAD_Wrapper_tb_large is

    function to_bin_str(sig : std_logic_vector) return string is
        variable result : string(1 to sig'length);
    begin
        for i in sig'range loop
            result(sig'length - i + sig'low) := character'VALUE(std_ulogic'image(sig(i)));
        end loop;
        return result;
    end function;


    -- Parametri di test
    constant Nbit        : positive := 8;
    constant N           : positive := 128;  -- N grande, caso limite
    constant NUM_IMAGES  : positive := 10;
    -- Calcolo dinamicamente la grandezza (in bit) dei vettori
    constant COUNT_WIDTH   : positive := clog2(N * N) + 2;
    constant SAD_WIDTH     : positive := clog2((2**Nbit - 1) * N * N) + 2;
    constant IMG_IDX_WIDTH : positive := clog2(NUM_IMAGES) + 2;

    constant clk_period  : time := 100 ns;

    -- Stimoli e segnali
    signal clk     : std_logic := '0';
    signal rst     : std_logic := '1';
    signal enable  : std_logic := '0';
    signal pixel_A : std_logic_vector(Nbit-1 downto 0) := (others => '0');
    signal pixel_B : std_logic_vector(Nbit-1 downto 0) := (others => '0');

    signal sad_result        : std_logic_vector(SAD_WIDTH-1 downto 0);
    signal result_valid      : std_logic;
    signal result_image_idx  : std_logic_vector(IMG_IDX_WIDTH - 1 downto 0);

    -- Immagini
    type image_array is array (0 to N*N-1) of std_logic_vector(Nbit-1 downto 0);
    type image_list  is array (0 to NUM_IMAGES-1) of image_array;

    signal images_A : image_list;
    signal images_B : image_list;

    signal testing : boolean := true;

begin

    -- Clock generation
    clk <= not clk after clk_period / 2 when testing else '0';

    -- Unit Under Test
    DUT: entity work.SAD_Wrapper
        generic map (
            Nbit          => Nbit,
            N             => N,
            NUM_IMAGES    => NUM_IMAGES,
            SAD_WIDTH     => SAD_WIDTH,
            COUNT_WIDTH   => COUNT_WIDTH,
            IMG_IDX_WIDTH => IMG_IDX_WIDTH
        )
        port map (
            clk     => clk,
            rst     => rst,
            en      => enable,
            pixel_A => pixel_A,
            pixel_B => pixel_B,

            sad_result       => sad_result,
            result_valid     => result_valid,
            result_image_idx => result_image_idx
        );

    -- Stimuli: immagini da confrontare
    stim_gen: process
        variable diff_value      : integer := 5;
        variable expected_sad    : integer := 0;
        type sad_array is array(0 to NUM_IMAGES-1) of integer;
        variable expected_sads   : sad_array := (others => 0);

        variable a_val, b_val    : integer;
    begin
        -- Reset
        rst <= '1';
        wait for 300 ns;
        rst <= '0';
        wait for 400 ns;
        enable  <= '1';

        -- Inizializza immagini e calcola SAD attesi
        for img in 0 to NUM_IMAGES-1 loop
            expected_sad := 0;

            for p in 0 to N*N-1 loop
                a_val := (p * 10) mod 256;
                b_val := (p * 10 + diff_value + img) mod 256;

                images_A(img)(p) <= std_logic_vector(to_unsigned(a_val, Nbit));
                images_B(img)(p) <= std_logic_vector(to_unsigned(b_val, Nbit));

                expected_sad := expected_sad + abs(a_val - b_val);
            end loop;

            expected_sads(img) := expected_sad;
            report "Expected SAD for image " & integer'image(img) & " = " & integer'image(expected_sad);
        end loop;

        wait until rising_edge(clk);

        -- Invio streaming dei pixel immagine per immagine
        for img in 0 to NUM_IMAGES-1 loop
            for p in 0 to N*N-1 loop
                pixel_A <= images_A(img)(p);
                pixel_B <= images_B(img)(p);
                wait until rising_edge(clk);
            end loop;
            -- Pausa tra immagini
            pixel_A <= (others => '0');
            pixel_B <= (others => '0');
            wait for 3 * clk_period;

            -- Confronto
            assert to_integer(unsigned(sad_result)) = expected_sads(img)
                report "Errore: SAD calcolato diverso da atteso per immagine " & integer'image(img)
                & ". Atteso: " & integer'image(expected_sads(img))
                & ", Calcolato: " & integer'image(to_integer(unsigned(sad_result)))
                severity error;

            report "SAD [" & integer'image(img) & "] OK. Binario: " & to_bin_str(sad_result);

        end loop;

        enable <= '0';
        wait for 10 * clk_period;
        testing <= false;
        wait;
    end process;

end architecture;
