`timescale 1ns / 10ps
module FourBankFIFO(
    input           clk         ,
    input           rst         ,
    input           wr_en_M0    ,
    input  [7:0]    data_in_M0  ,
    input           rd_en_M0    ,
    input  [1:0]    rd_id_M0    ,
    input           wr_en_M1    ,
    input  [7:0]    data_in_M1  ,
    input           rd_en_M1    ,
    input  [1:0]    rd_id_M1    ,
    output [7:0]    data_out_M0 ,
    output [7:0]    data_out_M1 ,
    output          valid_M0    ,
    output          valid_M1
);

	wire grant_M0;
    wire grant_M1;
	wire req_M0 = wr_en_M0 | rd_en_M0;
	wire req_M1 = wr_en_M1 | rd_en_M1;
	
    // Master Arbiter (Round Robin)
	Master_Arbiter u_Master_Arbiter (
		.clk	  (clk)		 ,
		.rst	  (rst)		 ,
		.req_M0   (req_M0)	 ,
		.req_M1	  (req_M1)	 ,
		.grant_M0 (grant_M0) ,
        .grant_M1 (grant_M1)
	);
	
    // FIFO Bank Arbiter (LRU & Routing)
	
	// FIFO Sync Instances (4 Banks)

endmodule

module Master_Arbiter(
	input      clk		,
	input 	   rst		,
	input 	   req_M0	,
	input 	   req_M1	,
	output reg grant_M0 ,
    output reg grant_M1
);
	reg last_grant;
	
	always @(*) begin
		grant_M0 = 0;
		grant_M1 = 0;
		
		if (req_M0 && req_M1) begin
			if (last_grant)
				grant_M0 = 1;
			else
				grant_M1 = 1;
		end else if (req_M0)
			grant_M0 = 1;
		else if (req_M1)
			grant_M1 = 1;
	end
	always @(posedge clk or posedge rst) begin
        if (rst) 
            last_grant <= 0;
        else begin
            if (grant_M0) 
				last_grant <= 0;
            if (grant_M1) 
				last_grant <= 1;
        end
    end
endmodule