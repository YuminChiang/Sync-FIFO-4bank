`timescale 1ns / 10ps
`include "FIFO_sync.v"

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
    output reg          valid_M0,
    output reg          valid_M1
);
    wire M0_req; 
    wire M1_req;
    
    assign M0_req = wr_en_M0 || rd_en_M0;
    assign M1_req = wr_en_M1 || rd_en_M1;


    wire [3:0] full;
    wire [3:0] empty;

    reg [7:0] data_in [0:3];

    wire [7:0] data_out [0:3];

    wire [3:0] wr_en;
    
    wire rd_en [0:3];

    
    reg rd_bank [0:3];


    master_arb ma(
        .clk(clk),
        .rst(rst),
        .M0_req(M0_req),
        .M1_req(M1_req),
        .rd_en_M0(rd_en_M0),
        .wr_en_M0(wr_en_M0),
        .rd_en_M1(rd_en_M1),
        .wr_en_M1(wr_en_M1),
        .arb_rd_en_M0(arb_rd_en_M0),
        .arb_wr_en_M0(arb_wr_en_M0),
        .arb_rd_en_M1(arb_rd_en_M1),
        .arb_wr_en_M1(arb_wr_en_M1)
    );

    bank_arb ba(
        .clk(clk),
        .rst(rst),
        .arb_wr_en_M0(arb_wr_en_M0),
        .arb_wr_en_M1(arb_wr_en_M1),
        .full(full),
        .wr_en(wr_en)
    );

    assign data_out_M0 = (rd_bank[0]) ? data_out[0] : (rd_bank[1]) ? data_out[1] : (rd_bank[2]) ? data_out[2] : (rd_bank[3]) ? data_out[3] : 8'd0;
    assign data_out_M1 = (rd_bank[0]) ? data_out[0] : (rd_bank[1]) ? data_out[1] : (rd_bank[2]) ? data_out[2] : (rd_bank[3]) ? data_out[3] : 8'd0;


    

    assign rd_en[3] = ((~empty[3] && arb_rd_en_M0) && (rd_id_M0 == 2'b11) ) ? 1'b1 : ((~empty[3] && arb_rd_en_M1) && (rd_id_M1 == 2'b11) ) ? 1'b1 : 1'b0;
    assign rd_en[2] = ((~empty[2] && arb_rd_en_M0) && (rd_id_M0 == 2'b10) ) ? 1'b1 : ((~empty[2] && arb_rd_en_M1) && (rd_id_M1 == 2'b10) ) ? 1'b1 : 1'b0;
    assign rd_en[1] = ((~empty[1] && arb_rd_en_M0) && (rd_id_M0 == 2'b01) ) ? 1'b1 : ((~empty[1] && arb_rd_en_M1) && (rd_id_M1 == 2'b01) ) ? 1'b1 : 1'b0;
    assign rd_en[0] = ((~empty[0] && arb_rd_en_M0) && (rd_id_M0 == 2'b00) ) ? 1'b1 : ((~empty[0] && arb_rd_en_M1) && (rd_id_M1 == 2'b00) ) ? 1'b1 : 1'b0;

    

    assign data_in[0] = wr_en[0] ? arb_wr_en_M0 ? data_in_M0 : arb_wr_en_M1 ? data_in_M1 : 8'd0 : 8'd0;
    assign data_in[1] = wr_en[1] ? arb_wr_en_M0 ? data_in_M0 : arb_wr_en_M1 ? data_in_M1 : 8'd0 : 8'd0;
    assign data_in[2] = wr_en[2] ? arb_wr_en_M0 ? data_in_M0 : arb_wr_en_M1 ? data_in_M1 : 8'd0 : 8'd0;
    assign data_in[3] = wr_en[3] ? arb_wr_en_M0 ? data_in_M0 : arb_wr_en_M1 ? data_in_M1 : 8'd0 : 8'd0;

 

    FIFO_sync f0(
  	    .clk(clk),
        .rst(rst),
        .wr_en(wr_en[0]),
        .rd_en(rd_en[0]),
        .data_in(data_in[0]),
        .full(full[0]),
        .empty(empty[0]),
        .data_out(data_out[0])
   
    );
    FIFO_sync f1(
  	    .clk(clk),
        .rst(rst),
        .wr_en(wr_en[1]),
        .rd_en(rd_en[1]),
        .data_in(data_in[1]),
        .full(full[1]),
        .empty(empty[1]),
        .data_out(data_out[1])

    );
    FIFO_sync f2(
  	    .clk(clk),
        .rst(rst),
        .wr_en(wr_en[2]),
        .rd_en(rd_en[2]),
        .data_in(data_in[2]),
        .full(full[2]),
        .empty(empty[2]),
        .data_out(data_out[2])

    );
    FIFO_sync f3(
  	    .clk(clk),
        .rst(rst),
        .wr_en(wr_en[3]),
        .rd_en(rd_en[3]),
        .data_in(data_in[3]),
        .full(full[3]),
        .empty(empty[3]),
        .data_out(data_out[3])

    );
 
   
    


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            valid_M0     = 0;
            valid_M1     = 0;
        end
        else begin
            rd_bank[0] = rd_en[0];
            rd_bank[1] = rd_en[1];
            rd_bank[2] = rd_en[2];
            rd_bank[3] = rd_en[3];

            valid_M0 = arb_rd_en_M0 & ( (rd_id_M0 == 2'b00 & ~empty[0]) | (rd_id_M0 == 2'b01 & ~empty[1]) | (rd_id_M0 == 2'b10 & ~empty[2]) | (rd_id_M0 == 2'b11 & ~empty[3]) );
            valid_M1 = arb_rd_en_M1 & ( (rd_id_M1 == 2'b00 & ~empty[0]) | (rd_id_M1 == 2'b01 & ~empty[1]) | (rd_id_M1 == 2'b10 & ~empty[2]) | (rd_id_M1 == 2'b11 & ~empty[3]) );          
        end
    end
endmodule

module master_arb(
    input clk,
    input rst,
    input M0_req,
    input M1_req,
    input rd_en_M0,
    input wr_en_M0,
    input rd_en_M1,
    input wr_en_M1,
    output arb_rd_en_M0,
    output arb_wr_en_M0,
    output arb_rd_en_M1,
    output arb_wr_en_M1
);

    reg last_master;

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            last_master = 1;
        end else begin
            case ({M0_req, M1_req})
                2'b11: last_master = ~last_master;
                2'b10: last_master = 1'b0;
                2'b01: last_master = 1'b1;
                default: ;
            endcase
        end
    end

    assign arb_rd_en_M0 = (M0_req & M1_req) ? (last_master) & rd_en_M0 : (M0_req) ? rd_en_M0 : 1'b0;
    assign arb_wr_en_M0 = (M0_req & M1_req) ? (last_master) & wr_en_M0 : (M0_req) ? wr_en_M0 : 1'b0;
    assign arb_rd_en_M1 = (M0_req & M1_req) ? (~last_master) & rd_en_M1 : (M1_req) ? rd_en_M1 : 1'b0;
    assign arb_wr_en_M1 = (M0_req & M1_req) ? (~last_master) & wr_en_M1 : (M1_req) ? wr_en_M1 : 1'b0;

endmodule

module bank_arb(
    input clk,
    input rst,
    input arb_wr_en_M0,
    input arb_wr_en_M1,
    input [3:0] full,
    output [3:0] wr_en
);

    reg [1:0] lru_order [0:3];
    reg [1:0] lru_buffer;
    reg wr_success;

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            lru_order[0] = 0;
            lru_order[1] = 1;
            lru_order[2] = 2;
            lru_order[3] = 3;
            wr_success = 0;
        end else begin
            if (arb_wr_en_M0 || arb_wr_en_M1) begin
                if(wr_success) begin
                    lru_buffer = lru_order[0];
                    lru_order[0] = lru_order[1];
                    lru_order[1] = lru_order[2];
                    lru_order[2] = lru_order[3];
                    lru_order[3] = lru_buffer;
                    wr_success = 0;
                end
            end
        end
    end

    assign wr_success = (wr_en[0] || wr_en[1] || wr_en[2] || wr_en[3]) ? 1'b1 : 1'b0;

    assign wr_en[3] = ((~full[3] && arb_wr_en_M0) && (lru_order[0] == 2'b11)) ? 1'b1 : ((~full[3] && arb_wr_en_M1) && (lru_order[0] == 2'b11)) ? 1'b1 : 1'b0;
    assign wr_en[2] = ((~full[2] && arb_wr_en_M0) && (lru_order[0] == 2'b10)) ? 1'b1 : ((~full[2] && arb_wr_en_M1) && (lru_order[0] == 2'b10)) ? 1'b1 : 1'b0;
    assign wr_en[1] = ((~full[1] && arb_wr_en_M0) && (lru_order[0] == 2'b01)) ? 1'b1 : ((~full[1] && arb_wr_en_M1) && (lru_order[0] == 2'b01)) ? 1'b1 : 1'b0;
    assign wr_en[0] = ((~full[0] && arb_wr_en_M0) && (lru_order[0] == 2'b00)) ? 1'b1 : ((~full[0] && arb_wr_en_M1) && (lru_order[0] == 2'b00)) ? 1'b1 : 1'b0;

endmodule