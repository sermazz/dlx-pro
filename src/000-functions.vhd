--#######################################################################################
--
--					DLX ARCHITECTURE - Custom Implementation (PRO version)
--								Politecnico di Torino
--						  Microelectronic Systems, A.Y. 2018/19
--							  Prof. Mariagrazia Graziano
--
-- Author: Sergio Mazzola
-- Contact: s.mazzola@outlook.com
-- 
-- File: 000-functions.vhd
-- Date: August 2019
-- Brief: Definition of project-wide useful functions
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;

package functions is

	function makeDivisible (n:integer; m:integer) return integer;
	function log2(n:integer) return integer;
	function ceilDiv(n:integer; m:integer) return integer;

end functions;

package body functions is

	function makeDivisible (n:integer; m:integer) return integer is
	-- Returns the first integer number greater or equal to n
	-- which is a multiple of the integer m
		variable Ntemp : integer := n;
	begin
		while ((Ntemp mod m) /= 0) loop
			Ntemp := Ntemp + 1;
		end loop;
		return Ntemp;
	end makeDivisible;
	
	function log2(n:integer) return integer is
	-- Calculates iteratively the base 2 logarithm of the integer
	-- n, approximating it to the ceil integer
	begin
		if n <=2 then
			return 1;
		else
			return 1 + log2(ceilDiv(n,2));
		end if;
	end function log2;

	function ceilDiv(n:integer; m:integer) return integer is
	-- Returns ceil(n/m), where n and m are integers
		variable Ntemp : integer;
	begin
		if ((n mod m) = 0) then
			return n/m;
		else
			-- Because integer division n/m acts like floor(n/m)
			return n/m+1;
		end if;
	end function ceilDiv;
	
end functions;
