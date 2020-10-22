module Alarm_Clock(
	input clk, reset, set, set_hh, set_mm, set_btn, mode_btn,
	output reg [6:0] ss7_lsd, ss7_msd, mm7_lsd, mm7_msd, hh7_lsd, hh7_msd,
	output reg dp_ss,
	output reg [9:0] led,
	output reg buzzer,
	output reg [1:0] ps
	);

//Parameters for Mode-states and 7-Segment displays
parameter d0=7'b1000000, d1=7'b1111001, d2=7'b0100100, d3=7'b0110000, d4=7'b0011001, d5=7'b0010010, d6=7'b0000010, d7=7'b1111000, d8=7'b0000000, d9=7'b0011000;
parameter state_Reset=2'b00, state_Alarm=2'b01, state_Timer=2'b10, state_Stopw=2'b11;


//Clock Divider
reg [32:0] clock_counter;
reg clk_1s;

initial begin
clock_counter = 0;
clk_1s = 0;
end

always @(posedge clk)begin

		clock_counter = clock_counter + 1;
		if(clock_counter == 25000000) begin
			clk_1s = ~clk_1s;
			clock_counter = 0;
		end

end



//Next State Logic
reg [1:0] Current_State, Next_State;

initial begin
	Current_State = state_Reset;

end

always @(*) begin
	
	case(Current_State)
		state_Reset: if(mode_btn == 0) begin Next_State = state_Alarm; end
			     else if (mode_btn == 1) begin Next_State = state_Reset; end
		state_Alarm: if(mode_btn == 0) begin Next_State = state_Timer; end
			     else if (mode_btn == 1) begin Next_State = state_Alarm; end
		state_Timer: if(mode_btn == 0) begin Next_State = state_Stopw; end
			     else if (mode_btn == 1) begin Next_State = state_Timer; end
		state_Stopw: if(mode_btn == 0) begin Next_State = state_Reset; end
			     else if (mode_btn == 1) begin Next_State = state_Stopw; end
		default: Next_State = state_Reset;
	endcase 					
end


//Update State
always @(posedge clk_1s) begin

	if(set == 0)
		Current_State <= Next_State;

end



//Time Counter
reg [6:0] hour, min, sec;

initial begin
	hour = 0;
	min = 0;
	sec = 0;
end

always @(posedge clk_1s) begin

		if ((set == 1) && (Current_State == state_Reset))begin
			min = set_min;
			hour = set_hour;
			sec = set_sec;
		end
		else begin
			sec = sec + 1;
			if (sec == 60) begin
				min = min + 1;
				sec = 0;
			end

			if (min == 60) begin
				hour = hour + 1;
				min = 0;
			end
			
			if (hour == 24) begin
				hour = 0;
			end
		end
end


//Set Logic
reg [6:0] set_hour, set_min, set_sec;

always @(posedge clk_1s) begin

	if( (set == 0)) begin
		set_hour = hour;
		set_min = min;
		set_sec = sec;
	end

	if ((set ==  1) && (set_mm == 1) && (set_hh == 0) && (set_btn == 0)) begin
		set_min = set_min + 1;
		if (set_min == 60) 
			set_min = 0;
	end
	else if ((set ==  1) && (set_mm == 0) && (set_hh == 1) && (set_btn == 0)) begin
		set_hour = set_hour + 1;
		if (set_hour == 24) 
			set_hour = 0;
	end
	

end


//Display Logic
always @(posedge clk_1s) begin

	if ((Current_State == state_Reset) && (set == 0))begin
		hh7_msd = get_msd(hour);
		hh7_lsd = get_lsd(hour);
		mm7_msd = get_msd(min);
		mm7_lsd = get_lsd(min);
		ss7_msd = get_msd(sec);
		ss7_lsd = get_lsd(sec);
	end
	else if ((Current_State == state_Reset) && (set == 1))begin
		hh7_msd = get_msd(set_hour);
		hh7_lsd = get_lsd(set_hour);
		mm7_msd = get_msd(set_min);
		mm7_lsd = get_lsd(set_min);
		ss7_msd = get_msd(set_sec);
		ss7_lsd = get_lsd(set_sec);
	end
	else if (Current_State == state_Alarm)begin
		hh7_msd = d2;
		hh7_lsd = d2;
		mm7_msd = get_msd(min);
		mm7_lsd = get_lsd(min);
		ss7_msd = get_msd(sec);
		ss7_lsd = get_lsd(sec);
	end
	else if (Current_State == state_Timer)begin
		hh7_msd = d3;
		hh7_lsd = d3;
		mm7_msd = get_msd(min);
		mm7_lsd = get_lsd(min);
		ss7_msd = get_msd(sec);
		ss7_lsd = get_lsd(sec);
	end
	else if (Current_State == state_Stopw)begin
		hh7_msd = d4;
		hh7_lsd = d4;
		mm7_msd = get_msd(min);
		mm7_lsd = get_lsd(min);
		ss7_msd = get_msd(sec);
		ss7_lsd = get_lsd(sec);
	end
	else begin
		hh7_msd = d1;
		hh7_lsd = d1;
		mm7_msd = d1;
		mm7_lsd = d1;
		ss7_msd = d1;
		ss7_lsd = d1;
	end
	
		
end


// Get most-significant-digit for display (binary number input)
function [6:0] get_msd;
	input [6:0] n;
	
	reg [6:0] m;
	m = n / 10;
	
	begin
			case(m)
				0 : get_msd = d0;
				1 : get_msd = d1;
				2 : get_msd = d2;
				3 : get_msd = d3;
				4 : get_msd = d4;
				5 : get_msd = d5;
				6 : get_msd = d6;
				7 : get_msd = d7;
				8 : get_msd = d8;
				9 : get_msd = d9;
				default: get_msd = d8;
			endcase
	end
endfunction


// Get lease-significant-digit for display (binary number input)
function [6:0] get_lsd;
	input [6:0] n;
	
	reg [6:0] m;
	
	if (n >= 10)
		m = n % 10;
	else
		m = n;
	
	begin
			case(m)
				0 : get_lsd = d0;
				1 : get_lsd = d1;
				2 : get_lsd = d2;
				3 : get_lsd = d3;
				4 : get_lsd = d4;
				5 : get_lsd = d5;
				6 : get_lsd = d6;
				7 : get_lsd = d7;
				8 : get_lsd = d8;
				9 : get_lsd = d9;
				default: get_lsd = d3;
			endcase
	end
endfunction


endmodule


