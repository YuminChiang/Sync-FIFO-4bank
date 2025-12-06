`timescale 1ns / 10ps
`include "FIFO_sync.v"

// Main FourBankFIFO module: Top-level module integrating arbitration and FIFO banks
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
    output          valid_M0,
    output          valid_M1
);
    // Request signals
    wire M0_req = wr_en_M0 || rd_en_M0;
    wire M1_req = wr_en_M1 || rd_en_M1;

    // FIFO status and data signals
    wire [3:0] full, empty;
    wire [7:0] data_in [0:3], data_out [0:3];
    wire [3:0] wr_en, rd_en;

    // Arbitration modules
    master_arb u_master_arb(
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

    bank_arb u_bank_arb(
        .clk(clk),
        .rst(rst),
        .arb_wr_en_M0(arb_wr_en_M0),
        .arb_wr_en_M1(arb_wr_en_M1),
        .full(full),
        .wr_en(wr_en),
        .arb_rd_en_M0(arb_rd_en_M0),
        .arb_rd_en_M1(arb_rd_en_M1),
        .rd_id_M0(rd_id_M0),
        .rd_id_M1(rd_id_M1),
        .empty(empty),
        .data_in_M0(data_in_M0),
        .data_in_M1(data_in_M1),
        .data_out_bank0(data_out[0]),
        .data_out_bank1(data_out[1]),
        .data_out_bank2(data_out[2]),
        .data_out_bank3(data_out[3]),
        .rd_en(rd_en),
        .data_out_M0(data_out_M0),
        .data_out_M1(data_out_M1),
        .valid_M0(valid_M0),
        .valid_M1(valid_M1),
        .data_in_bank0(data_in[0]),
        .data_in_bank1(data_in[1]),
        .data_in_bank2(data_in[2]),
        .data_in_bank3(data_in[3])
    );

    // FIFO instances using generate
    generate
        genvar i;
        for (i = 0; i < 4; i = i + 1) begin : fifo_inst
            FIFO_sync u_fifo (
                .clk(clk),
                .rst(rst),
                .wr_en(wr_en[i]),
                .rd_en(rd_en[i]),
                .data_in(data_in[i]),
                .full(full[i]),
                .empty(empty[i]),
                .data_out(data_out[i])
            );
        end
    endgenerate    
endmodule

// Master arbitration module: handles arbitration between two masters (M0 and M1)
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

    reg last_granted;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            last_granted = 1;
        end else begin
            case ({M0_req, M1_req})
                2'b11: last_granted = ~last_granted;
                2'b10: last_granted = 1'b0;
                2'b01: last_granted = 1'b1;
                default: ;
            endcase
        end
    end

    assign arb_rd_en_M0 = (M0_req & M1_req) ? (last_granted) & rd_en_M0 : (M0_req) ? rd_en_M0 : 1'b0;
    assign arb_wr_en_M0 = (M0_req & M1_req) ? (last_granted) & wr_en_M0 : (M0_req) ? wr_en_M0 : 1'b0;
    assign arb_rd_en_M1 = (M0_req & M1_req) ? (~last_granted) & rd_en_M1 : (M1_req) ? rd_en_M1 : 1'b0;
    assign arb_wr_en_M1 = (M0_req & M1_req) ? (~last_granted) & wr_en_M1 : (M1_req) ? wr_en_M1 : 1'b0;

endmodule

// Bank arbitration module: selects which bank to write using LRU policy and handles read logic
module bank_arb(
    input clk,
    input rst,
    input arb_wr_en_M0,
    input arb_wr_en_M1,
    input [3:0] full,
    output [3:0] wr_en,
    input arb_rd_en_M0,
    input arb_rd_en_M1,
    input [1:0] rd_id_M0,
    input [1:0] rd_id_M1,
    input [3:0] empty,
    input [7:0] data_in_M0,
    input [7:0] data_in_M1,
    input [7:0] data_out_bank0,
    input [7:0] data_out_bank1,
    input [7:0] data_out_bank2,
    input [7:0] data_out_bank3,
    output [3:0] rd_en,
    output [7:0] data_out_M0,
    output [7:0] data_out_M1,
    output reg valid_M0,
    output reg valid_M1,
    output [7:0] data_in_bank0,
    output [7:0] data_in_bank1,
    output [7:0] data_in_bank2,
    output [7:0] data_in_bank3
);
    reg [1:0] lru_order [0:3];
    reg [1:0] lru_buffer;
    reg [3:0] rd_bank;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            lru_order[0] = 0;
            lru_order[1] = 1;
            lru_order[2] = 2;
            lru_order[3] = 3;
            valid_M0 = 0;
            valid_M1 = 0;
            rd_bank = 4'b0;
        end else begin
            if (arb_wr_en_M0 || arb_wr_en_M1) begin
                // Check if any write succeeded
                if (wr_en[0] || wr_en[1] || wr_en[2] || wr_en[3]) begin
                    lru_buffer = lru_order[0];
                    lru_order[0] = lru_order[1];
                    lru_order[1] = lru_order[2];
                    lru_order[2] = lru_order[3];
                    lru_order[3] = lru_buffer;
                end
            end
            // Track which bank was read
            rd_bank[0] = rd_en[0];
            rd_bank[1] = rd_en[1];
            rd_bank[2] = rd_en[2];
            rd_bank[3] = rd_en[3];

            // Set valid signals based on read arbitration and bank emptiness
            valid_M0 = arb_rd_en_M0 && ((rd_id_M0 == 2'b00 && ~empty[0]) || (rd_id_M0 == 2'b01 && ~empty[1]) || (rd_id_M0 == 2'b10 && ~empty[2]) || (rd_id_M0 == 2'b11 && ~empty[3]));
            valid_M1 = arb_rd_en_M1 && ((rd_id_M1 == 2'b00 && ~empty[0]) || (rd_id_M1 == 2'b01 && ~empty[1]) || (rd_id_M1 == 2'b10 && ~empty[2]) || (rd_id_M1 == 2'b11 && ~empty[3]));
        end
    end

    assign wr_en[3] = (~full[3] && arb_wr_en_M0 && (lru_order[0] == 2'b11)) || (~full[3] && arb_wr_en_M1 && (lru_order[0] == 2'b11));
    assign wr_en[2] = (~full[2] && arb_wr_en_M0 && (lru_order[0] == 2'b10)) || (~full[2] && arb_wr_en_M1 && (lru_order[0] == 2'b10));
    assign wr_en[1] = (~full[1] && arb_wr_en_M0 && (lru_order[0] == 2'b01)) || (~full[1] && arb_wr_en_M1 && (lru_order[0] == 2'b01));
    assign wr_en[0] = (~full[0] && arb_wr_en_M0 && (lru_order[0] == 2'b00)) || (~full[0] && arb_wr_en_M1 && (lru_order[0] == 2'b00));

    // Read enable logic
    assign rd_en[3] = (~empty[3] && arb_rd_en_M0 && (rd_id_M0 == 2'b11)) || (~empty[3] && arb_rd_en_M1 && (rd_id_M1 == 2'b11));
    assign rd_en[2] = (~empty[2] && arb_rd_en_M0 && (rd_id_M0 == 2'b10)) || (~empty[2] && arb_rd_en_M1 && (rd_id_M1 == 2'b10));
    assign rd_en[1] = (~empty[1] && arb_rd_en_M0 && (rd_id_M0 == 2'b01)) || (~empty[1] && arb_rd_en_M1 && (rd_id_M1 == 2'b01));
    assign rd_en[0] = (~empty[0] && arb_rd_en_M0 && (rd_id_M0 == 2'b00)) || (~empty[0] && arb_rd_en_M1 && (rd_id_M1 == 2'b00));

    // Data input multiplexing
    assign data_in_bank0 = wr_en[0] ? (arb_wr_en_M0 ? data_in_M0 : data_in_M1) : 8'd0;
    assign data_in_bank1 = wr_en[1] ? (arb_wr_en_M0 ? data_in_M0 : data_in_M1) : 8'd0;
    assign data_in_bank2 = wr_en[2] ? (arb_wr_en_M0 ? data_in_M0 : data_in_M1) : 8'd0;
    assign data_in_bank3 = wr_en[3] ? (arb_wr_en_M0 ? data_in_M0 : data_in_M1) : 8'd0;

    // Data output multiplexing
    assign data_out_M0 = rd_bank[0] ? data_out_bank0 : rd_bank[1] ? data_out_bank1 : rd_bank[2] ? data_out_bank2 : rd_bank[3] ? data_out_bank3 : 8'd0;
    assign data_out_M1 = rd_bank[0] ? data_out_bank0 : rd_bank[1] ? data_out_bank1 : rd_bank[2] ? data_out_bank2 : rd_bank[3] ? data_out_bank3 : 8'd0;

endmodule