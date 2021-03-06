--  Hello world program
library ieee;
library work;
use std.textio.all; -- Imports the standard textio package.
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.oxiToAxiFIFO;
use work.oxiToAxiSkid;
use work.oxiToAxiBurstTransposer;

--  Defines a design entity, without any ports.
entity test_oxiToAxiFIFO is
end test_oxiToAxiFIFO;

architecture behaviour of test_oxiToAxiFIFO is
	constant testSkid: boolean := false;
	signal bytesIssued: unsigned(31 downto 0);
	
	subtype data_t is std_logic_vector(15 downto 0);
	subtype dataOut_t is std_logic_vector(15 downto 0);
	
	signal inData: data_t;
	signal inClk, inpValid, inReady,inReady1,inReady2,inReady3: std_logic := '0';
	signal outData: dataOut_t;
	signal outValid, outReady: std_logic := '0';
	
	constant inClkHPeriod: time := 20.5 ns;
	
	function inputSpeed(I: integer) return integer is
	begin
		if I<100 then
			return 5;
		elsif I<200 then
			return 1;
		elsif I<300 then
			return 7;
		else
			return 2;
		end if;
	end function;
	function outputSpeed(I: integer) return integer is
	begin
		if I<100 then
			return 5;
		elsif I<200 then
			return 10;
		elsif I<300 then
			return 1;
		else
			return 1;
		end if;
	end function;
begin

g1: if testSkid generate
		inst: entity oxiToAxiSkid generic map(width=>16,depthOrder=>4)
			port map(inClk,
				inpValid, inReady, inData,
				outValid, outReady, outData);
	end generate;
g2: if not testSkid generate
		inst: entity oxiToAxiFIFO generic map(width=>16,depthOrder=>5)
			port map(inClk,
				inpValid, inReady, inData,
				outValid, outReady, outData);
	end generate;
	
	

	inReady1 <= inReady when rising_edge(inClk);
	inReady2 <= inReady1 when rising_edge(inClk);
	inReady3 <= inReady2 when rising_edge(inClk);


	-- feed data in
	process
		variable l : line;
		variable inpValue: integer := 0;
		variable expectValue: integer := 0;
		variable expectData: unsigned(15 downto 0);
	begin
		wait for inClkHPeriod; inClk <= '1'; wait for inClkHPeriod; inClk <= '0';
		wait for inClkHPeriod; inClk <= '1'; wait for inClkHPeriod; inClk <= '0';
		for I in 0 to 500 loop
		
			-- feed data in
			inpValid <= '0';
			if (I mod inputSpeed(I)) = 0 then
				if inReady3='1' then
					inpValid <= '1';
					inData <= data_t(to_unsigned(inpValue,16));
					inpValue := inpValue+1;
				end if;
			end if;
			
			
			-- retrieve data
			if ((I+2) mod outputSpeed(I)) = 0 then
				outReady <= '1';
				expectData := to_unsigned(expectValue, 16);
				if outValid='1' then
					assert expectData=unsigned(outData);
					expectValue := expectValue+1;
				end if;
			else
				outReady <= '0';
			end if;
			
			wait for inClkHPeriod; inClk <= '1'; wait for inClkHPeriod; inClk <= '0';
		end loop;
		
		wait;
	end process;
end behaviour;
