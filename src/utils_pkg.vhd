-- File: utils_pkg.vhd
package utils_pkg is
    function clog2(x: positive) return natural;
end package;

package body utils_pkg is
    function clog2(x: positive) return natural is
        variable res : natural := 0;
        variable val : natural := x - 1;
    begin
        assert x > 0 report "clog2(): input must be > 0" severity failure;
        while val > 0 loop
            res := res + 1;
            val := val / 2;
        end loop;
        return res;
    end function;
end package body;
