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

/*
	Write Your Design Here ~
*/


endmodule