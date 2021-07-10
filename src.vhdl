library ieee;


-- it gives out the cathode values for the input integer
entity to_display is port (
    inn : in integer;
    outt : out std_logic_vector(7 downto 0)
);
end to_display;

architecture to_display_arch of to_display is
    begin
        process(inn)
        begin
            case inn is
    -- << // 0 --> active, 1 --> not active // >>
    -- note the last bit is for the decimal point
    --  B == blinking dot      <<  abcdefgB  >>
                when 0 => outt <= "00000011";
                when 1 => outt <= "10011111";
                when 2 => outt <= "00100101";
                when 3 => outt <= "00001101";
                when 4 => outt <= "10011001";
                when 5 => outt <= "01001001";
                when 6 => outt <= "11000001";
                when 7 => outt <= "00011011";
                when 8 => outt <= "00000001";
                when 9 => outt <= "00001001";
                when others => null;
            end case;
        end process;
    end to_display_arch;


entity dig_clock is port (
    display_mode, set_button, increment, decrement, reset : in std_logic; --push buttons
    clk : in std_logic; -- << 100MHz >>
    anodes : out std_logic_vector(3 downto 0);
    cathodes : out std_logic_vector(7 downto 0)
);
end dig_clock;

architecture main of dig_clock is

    signal myclk1, myclk2, myclk3, blink : std_logic := '1';
    --        10Hz  2Hz     250Hz   derived clock signals

    signal count1, count2, count3 : integer := 1;
    --      used for creating derived clocks

    signal h1, h0, m1, m0, s1, s0, x : integer := 0;
    --      H1 H0 . M1 M0  // M1 M0 . S1 S0

    signal h1_disp, h0_disp, m1_disp, m0_disp, s1_disp, s0_disp : std_logic_vector(7 downto 0);
    signal st1, st2, st3, st4, st5, st6 : integer := 0; -- could have used array too
    signal state : integer := 0;
    signal disp : std_logic := '1'; -- to toggle display modes
    signal prev_display_mode, prev_set_button, prev_increment, prev_decrement, prev_reset : std_logic := '0';
    -- used to detect the push buttons

    component to_display port (
        inn : in integer;
        outt : out std_logic_vector(7 downto 0)
    );
    end component;

    begin
    -- << desired frequency clocks >>
    -- << clk1 = 1Hz    clk2 = 2Hz   clk3 = 250Hz >>
    process(clk)
        begin
            if rising_edge(clk) then
                count1 <= count1 + 1;
                count2 <= count2 + 1;
                count3 <= count3 + 1;
                if count1 = 100000000  then
                    myclk1 <= not myclk1;
                    count1 <= 1;
                end if;
                if count2 = 50000000 then
                    myclk2 <= not myclk2;
                    count2 <= 1;
                end if;
                if count3 = 400000 then
                    myclk3 <= not myclk3;
                    count3 <= 1;
                end if;
            end if;
    end process

    -- brings back to display state if left idle on set state for more than 6 seconds
    -- (i.e will have to change one digit in under 6 seconds)
    process(myclk1)
    begin
        st1 <= st2;
        st2 <= st3;
        st3 <= st4;
        st4 <= st5;
        st5 <= st6;
        st6 <= state;
        if ((st1 = st2) and (st2 = st3) and (st3 = st4) and (st4 = st5) and (st5 = st6)) then
            state = 0;
        end if;
    end process;

    process(myclk1, display_mode, set_button, increment, decrement, reset)
    begin
        if(reset = '1') then
            s0 <= 0;
            s1 <= 0;
            m0 <= 0;
            m1 <= 0;
            h0 <= 0;
            h1 <= 0;
            state <= 0;
            x <= 0;
            disp <= '1';
        else
            if rising_edge(myclk1) then
                s0 <= s0+1;
                -- taking care of overflow in time
                if s0 = 10 then
                    s0 <= 0;
                    s1 <= s1+1;
                    if s1 = 6 then
                        s1 <= 0;
                        m0 <= m0+1;
                        if m0 = 10 then
                            m0 <= 0;
                            m1 <= m1+1;
                            if m1 = 6 then
                                m1 <= 0;
                                h0 <= h0+1;
                                if h1 = 2 then
                                    if h0 = 4 then
                                        h0 <= 0;
                                        h1 <= 0;
                                    end if;
                                else
                                    if h0 = 10 then
                                        h0 <= 0;
                                        h1 <= h1+1;
                                    end if;
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;

        if prev_set_button = '0' and set_button = '1' then
        -- if rising_edge(set_button) then
            state <= state + 1;
            if state = 5 then
                state <= 0;
            end if;
        end if;
        prev_set_button <= set_button;

        if prev_increment = '0' and increment = '1' then
        -- if rising_edge(increment) then
            case state is
                when 0 =>
                    m0 <= m0; m1 <= m1; s0 <= s0; s1 <= s1;  h0 <= h0; h1 <= h1;
                when 1 =>
                    m0 <= m0 + 1;
                    if m0 = 10 then
                        m0 <= 0;
                    end if;
                when 2 =>
                    m1 <= m1 + 1;
                    if m1 = 6 then
                        m1 <= 0;
                    end if;
                when 3 =>
                    h0 <= h0 + 1;
                    if h0 = 10 then
                        h0 <= 0;
                    end if;
                when 4 =>
                    h1 <= h1 + 1;
                    if h1 = 3 then
                        h1 <= 0;
                    end if;
            end case;
        end if;
        prev_increment <= increment;

        if prev_decrement = '0' and decrement = '1' then
        -- if rising_edge(decrement) then
            case state is
                when 0 =>
                    m0 <= m0; m1 <= m1; s0 <= s0; s1 <= s1;  h0 <= h0; h1 <= h1;
                when 1 =>
                    m0 <= m0 - 1;
                    if m0 = -1 then
                        m0 <= 9;
                    end if;
                when 2 =>
                    m1 <= m1 - 1;
                    if m1 = -1 then
                        m1 <= 5;
                    end if;
                when 3 =>
                    h0 <= h0 - 1;
                    if h0 = -1 then
                        h0 <= 9;
                    end if;
                when 4 =>
                    h1 <= h1 - 1;
                    if h1 = -1 then
                        h1 <= 2;
                    end if;
            end case;
        end if;
        prev_decrement <= decrement;

        if prev_display_mode = '0' and display_mode = '1' then
        -- if rising_edge(display_mode) then
            disp <= not disp;
        end if;
        prev_display_mode = display_mode;

    end process;

-- instatiation statements for the using to_display here
    second0: to_display port map (inn => s0, outt => s0_disp);
    second1: to_display port map (inn => s1, outt => s1_disp);
    minute0: to_display port map (inn => m0, outt => m0_disp);
    minute1: to_display port map (inn => m1, outt => m1_disp);
    hour0: to_display port map (inn => h0, outt => h0_disp);
    hour1: to_display port map (inn => h1, outt => h1_disp);

    process(myclk2)
    -- facilitates the blinking decimal point
    begin
        if rising_edge(myclk2) then
            blink <= not blink;
        end if;
    end process;


    process(myclk3)
    --  displays the time
    begin
        if rising_edge(myclk3) then
            if disp = 0 then
                -- H H M M
                if x = 0 then
                    anodes <= '1110';
                    --  1 is not active, 0 is active
                    cathodes <= m0_disp;
                    x <= 1;
                elsif x = 1 then
                    anodes <= '1101';
                    cathodes <= m1_disp;
                    x <= 2;
                elsif x = 2 then
                    anodes <= '1011';
                    cathodes <= h0_disp;
                    cathodes(0) <= blink;
                    x <= 3;
                else
                    anodes <= '0111';
                    cathodes <= h1_disp;
                    x <= 0;
                end if;
            else
                -- MM SS
                if x = 0 then
                    anodes <= '1110';
                    cathodes <= s0_disp;
                    x <= 1;
                elsif x = 1 then
                    anodes <= '1101';
                    cathodes <= s1_disp;
                    x <= 2;
                elsif x = 2 then
                    anodes <= '1011';
                    cathodes <= m0_disp;
                    cathodes(0) <= blink;
                    x <= 3;
                else
                    anodes <= '0111';
                    cathodes <= m1_disp;
                    x <= 0;
                end if;
            end if;
        end if;
    end process;

end main;
