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

	wire [3:0]  bank_wr_en;
    wire [3:0]  bank_rd_en;
    wire [7:0]  wr_data;
	wire [31:0] rd_data;
	wire [3:0]  bank_full;
    wire [3:0]  bank_empty;
    
    // Master Arbiter (Round Robin)
	Master_Arbiter u_Master_Arbiter (
		.clk	  (clk),
		.rst	  (rst),
		.req_M0   (req_M0),
		.req_M1	  (req_M1),
		.grant_M0 (grant_M0),
        .grant_M1 (grant_M1)
	);
	
    // FIFO Bank Arbiter (LRU & Routing)
	
	// FIFO Sync Instances (4 Banks)
	// bank 0
	FIFO_sync u_BANK0 (
        .clk      (clk),
        .rst      (rst),
        .wr_en    (bank_wr_en[0]),
        .rd_en    (bank_rd_en[0]),
        .data_in  (bank_wr_data),
        .full     (bank_full[0]),
        .empty    (bank_empty[0]),
        .data_out (rd_data[7:0])
    );
 	// Bank 1
    FIFO_sync u_BANK1 (
        .clk      (clk),
        .rst      (rst),
        .wr_en    (bank_wr_en[1]),
        .rd_en    (bank_rd_en[1]),
        .data_in  (bank_wr_data),
        .full     (bank_full[1]),
        .empty    (bank_empty[1]),
        .data_out (rd_data[15:8])
    );

    // Bank 2
    FIFO_sync u_BANK2 (
        .clk      (clk),
        .rst      (rst),
        .wr_en    (bank_wr_en[2]),
        .rd_en    (bank_rd_en[2]),
        .data_in  (bank_wr_data),
        .full     (bank_full[2]),
        .empty    (bank_empty[2]),
        .data_out (rd_data[23:16])
    );

    // Bank 3
    FIFO_sync u_BANK3 (
        .clk      (clk),
        .rst      (rst),
        .wr_en    (bank_wr_en[3]),
        .rd_en    (bank_rd_en[3]),
        .data_in  (bank_wr_data),
        .full     (bank_full[3]),
        .empty    (bank_empty[3]),
        .data_out (rd_data[31:24])
    );
endmodule

module Master_Arbiter(
	input      clk,
	input 	   rst,
	input 	   req_M0,
	input 	   req_M1,
	output reg grant_M0,
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

module FIFO_Bank_Arbiter (
	input clk,
	input rst,
	input grant_M0,
	input grant_M1,
	input wr_en_M0,
	input [7:0] data_in_M0,
	input rd_en_M0,
	input rd_id_M0,
	input wr_en_M1,
	input [7:0] data_in_M1,
	input rd_en_M1,
	input rd_id_M1,
	input [3:0] bank_full,
	input [3:0] bank_empty,
	input [31:0] rd_data,
	output reg [3:0] bank_wr_en,
	output reg [3:0] bank_rd_en,
	output reg [7:0] wr_data,
	output reg [7:0] data_out_M0,
    output reg [7:0] data_out_M1,
	output reg valid_M0,
    output reg valid_M1
);
	reg [1:0] lru [0:3];

endmodule