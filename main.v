///////////////////////////////////////////////////////////
// Name File : main.v 												//
// Autor : Dyomkin Pavel Mikhailovich 							//
// Company : FLEXLAB													//
// Description : Test system single pixel					  	//
// Start design : 18.07.2022 										//
// Last revision : 09.08.2022 									//
///////////////////////////////////////////////////////////

module main (input clk_in, start_button, T_frame_switch, ADC_SDAT, reset,
	     
				 output reg Hold_IV, Reset_IV, D_out, ADC_start_convert, 
				 
				 output ADC_SCLK, ADC_CS_N, ADC_SADDR,
				 
				 output Tx_out 
				 );
				 

//////////////////////////// TOP MODULE REG/WIRE/PARAMETERS ///////////////////////////////////////////////////////////

parameter divider = 2000;
parameter t_frame_1sec = 50000000;
parameter t_frame_0_1sec = 50000; // !!!!не забыть поставить число 50 000 00!!!!!!!!!

		  
reg [7:0] state;	
reg [7:0] next_state;
//reg [7:0] state_cnt;
		  
localparam IDLE 							= 8'd0;
localparam START							= 8'd1;
localparam RESET_IV						= 8'd2;
localparam RECORDING						= 8'd3;
localparam HOLD_IV						= 8'd4;
localparam ADC								= 8'd5;
localparam WAIT_READY_CONVERTATION  = 8'd6;
localparam TRANSMITION					= 8'd7;
localparam STOP							= 8'd8;
		  
reg process_flg;
reg [32:0] cnt;
reg [32:0] Hz;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




//////////////////////////// ADC128S022_DRIVER MODULE REG/WIRE/PARAMETERS //////////////////////////////////////////////

wire [15:0] data_out;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




//////////////////////////// UART_Tx MODULE REG/WIRE/PARAMETERS ////////////////////////////////////////////////////////

reg launch_Tx;
wire transmit_flg;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		  
		  
initial begin
	
	Hold_IV = 1'b1;
	Reset_IV = 1'b1;
	D_out = 1'b0;
	
	ADC_start_convert <= 1'b1;
	launch_Tx <= 1'b1;
	
	
	state <= 1'b0;	
	next_state <= 1'b0;
	
	process_flg <= 1'b0;
	
	cnt <= 1'b0;
	
	Hz <= t_frame_0_1sec;

	
end		




			
always @* 	
		
		case (state)
			
			IDLE:
						
				
				if (start_button == 1'b0 && process_flg == 1'b0) begin
					next_state <= START;
				end
				
				else begin
					next_state <= IDLE;
				end
				
				
			START:	
			
				if (state == START) begin
					next_state <= RESET_IV;
				end
				
				else begin
					next_state <= START;
				end
			
			RESET_IV:	
			
				if (cnt == divider) begin
					next_state <= RECORDING;
				end
				
				else begin
					next_state <= RESET_IV;
				end
				
			RECORDING:	
			
				if (cnt == Hz + divider) begin
					next_state <= HOLD_IV;
				end
				
				else begin
					next_state <= RECORDING;
				end
				
			HOLD_IV:	
			
				if (cnt == Hz + divider * 2) begin
					next_state <= ADC;
				end
				
				else begin
					next_state <= HOLD_IV;
				end
			
			ADC:
			
				if (ADC_CS_N == 1'b0) begin // (cnt == Hz + divider * 2 + Hz / 100)
					next_state <= WAIT_READY_CONVERTATION;
				end
				
				else begin
					next_state <= ADC;
				end
				
			WAIT_READY_CONVERTATION:
			
				if (ADC_CS_N == 1'b1) begin 
					next_state <= TRANSMITION;
				end
				
				else begin
					next_state <= WAIT_READY_CONVERTATION;
				end
			
			TRANSMITION:
			
				if (transmit_flg == 1'b1) begin 
					next_state <= STOP;
				end
				
				else begin
					next_state <= TRANSMITION;
				end
			
			STOP:

				if (state == STOP) begin
					next_state <= IDLE;
				end
				
				else begin
					next_state <= STOP;
				end
		
				
				
			default:
				next_state <= IDLE;
		
		endcase
		
		
always @(posedge clk_in) begin
	
	if (T_frame_switch == 1'b0) begin
		Hz <= t_frame_0_1sec;
	end
	
	if (T_frame_switch == 1'b1) begin
		Hz <= t_frame_1sec;
	end
	
	
	if (start_button == 1'b0 && process_flg == 1'b0) begin
		process_flg <= 1'b1;					
		D_out <= 1'b1;
		Reset_IV <= 1'b0;
	end
	
	if (process_flg == 1'b1) begin
		cnt = cnt + 1'b1;
		
	end
	
	if (state == RESET_IV) begin

	end
	
	if (state == RECORDING) begin
		D_out <= 1'b0;
		Reset_IV <= 1'b1;
	end
	
	if (state == HOLD_IV) begin
		D_out <= 1'b1;
		Hold_IV <= 1'b0;
	end
	
	if (state == ADC) begin
		ADC_start_convert <= 1'b0;
		Hold_IV <= 1'b1;
		Reset_IV <= 1'b1;
		D_out <= 1'b0;
	end
	
	if (state != ADC) begin
		ADC_start_convert <= 1'b1;
	end
	
	if (state == TRANSMITION) begin
		launch_Tx <= 1'b0;
	end
	
	if (state != TRANSMITION) begin
		launch_Tx <= 1'b1;
	end
	
	
	if (state == STOP) begin
		Hold_IV <= 1'b1;
		Reset_IV <= 1'b1;
		D_out <= 1'b0;
		ADC_start_convert <= 1'b1;
	
		process_flg <= 1'b0;				

		
		cnt <= 1'b0;
		
		
		
	end
	
		
end	




always @(posedge clk_in or negedge reset) begin 
	
	
	if(!reset) begin
		state <= IDLE;
	end
	
	else begin
		state <= next_state;
	end
end		




ADC128S022_DRIVER ADC1 (.clk_in(clk_in), .reset(reset), .ADC_SDAT(ADC_SDAT),
						 .start_convert(ADC_start_convert), 
						 .ADC_SCLK(ADC_SCLK), .ADC_CS_N(ADC_CS_N), .ADC_SADDR(ADC_SADDR),
						 .data_out(data_out));
						 
						 
						 
UART_Tx TX1 (.clk_Tx(clk_in), .TX_LAUNCH(launch_Tx), .reset(reset), .transmit_flg(transmit_flg),
			.data_in(data_out[7:0]), .Tx_out(Tx_out));


	
	
endmodule



//data_out <=  {data_out[7:0], Rx_in}; shift reg