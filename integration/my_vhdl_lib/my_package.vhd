-- My dummy VHDL package
library ieee;
use ieee.std_logic_1164.all;

package my_package is
    function add (a, b: integer) return integer;
end package my_package;

package body my_package is
    function add (a, b: integer) return integer is
    begin
        return a + b;
    end function add;
end package body my_package;
