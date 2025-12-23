library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils_pkg.all;

entity SAD_Wrapper_tb is
end entity;

architecture sim of SAD_Wrapper_tb is

    -- Parametri di test
    constant Nbit        : positive := 8;
    constant N           : positive := 4;
    constant NUM_IMAGES  : positive := 3;
    -- Calcolo dinamicamente la grandezza (in bit) dei vettori
    constant COUNT_WIDTH   : positive := 6;    --clog2(N * N);
    constant SAD_WIDTH     : positive := 16;   --clog2((2**Nbit - 1) * N * N);
    constant IMG_IDX_WIDTH : positive := 4;    --clog2(NUM_IMAGES);

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
        variable diff_value : integer := 5;
	variable rand_seed : integer := 1;
	variable expected_sad_val : integer;
	variable a_val, b_val     : integer;
    begin
        -- Reset
        rst <= '1';
        wait for 300 ns;
        rst <= '0';
        wait for 400 ns;
        enable  <= '1';

        -- Inizializza immagini
        for img in 0 to NUM_IMAGES-1 loop
            for p in 0 to N*N-1 loop
                images_A(img)(p) <= std_logic_vector(to_unsigned(p * 10, Nbit));
                images_B(img)(p) <= std_logic_vector(to_unsigned(p * 10 + diff_value + img, Nbit));
            end loop;
        end loop;

        wait until rising_edge(clk);

        -- Invio streaming dei pixel immagine per immagine
        for img in 0 to NUM_IMAGES-1 loop
            for p in 0 to N*N-1 loop
                pixel_A <= images_A(img)(p);
                pixel_B <= images_B(img)(p);
                wait until rising_edge(clk);
            end loop;
            pixel_A <= (others => '0');
            pixel_B <= (others => '0');
            wait for 3*clk_period; -- dopo aver mandato un'immagine, 4*clk_period di pausa per garantire reset sad
        end loop;
        enable  <= '0';

        -- Attendi ultimi risultati prima prova
        wait for 10 * clk_period;

	-- Ora test con immagini generate casualmente
        for img in 0 to NUM_IMAGES - 1 loop
            expected_sad_val := 0;
            for p in 0 to N*N - 1 loop
                a_val := (1103515245 * rand_seed + 12345) mod 2**31;
                rand_seed := a_val;
                a_val := a_val mod 256;

                b_val := (1103515245 * rand_seed + 12345) mod 2**31;
                rand_seed := b_val;
                b_val := b_val mod 256;

                images_A(img)(p) <= std_logic_vector(to_unsigned(a_val, Nbit));
                images_B(img)(p) <= std_logic_vector(to_unsigned(b_val, Nbit));

                expected_sad_val := expected_sad_val + abs(a_val - b_val);
            end loop;
            report "Expected SAD for image " & integer'image(img) & ": " & integer'image(expected_sad_val);
        end loop;

        rst <= '1';
        wait for 300 ns;
        rst <= '0';
        wait for 200 ns;
	enable  <= '1';
        wait until rising_edge(clk);

        -- Invio streaming dei pixel immagine per immagine
        for img in 0 to NUM_IMAGES-1 loop
            for p in 0 to N*N-1 loop
                pixel_A <= images_A(img)(p);
                pixel_B <= images_B(img)(p);
                wait until rising_edge(clk);
            end loop;
            pixel_A <= (others => '0');
            pixel_B <= (others => '0');
            wait for 3*clk_period;
        end loop;
        enable  <= '0';

        -- Attendi ultimi risultati seconda prova
        wait for 10 * clk_period;

        testing <= false;
        wait;
    end process;

end architecture;

