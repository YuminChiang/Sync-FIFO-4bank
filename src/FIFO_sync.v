module FIFO_sync(
	input             clk     ,
    input             rst     ,
    input             wr_en   ,
    input             rd_en   ,
    input       [7:0] data_in ,
    output            full    ,
    output            empty   ,
    output      [7:0] data_out
);
	wire wr_valid;
	wire rd_valid;
	wire [4:0] wr_ptr;
    wire [4:0] rd_ptr;

	FIFO_mem u_FIFO_mem (
    	.clk      (clk)		 ,
        .rst      (rst)		 ,
        .wr_en    (wr_en)	 ,
        .rd_en    (rd_en)	 ,
        .wr_ptr   (wr_ptr)	 ,
        .rd_ptr   (rd_ptr)	 ,
        .data_in  (data_in)	 ,
        .data_out (data_out) ,
        .empty    (empty)	 ,
        .full     (full)	 ,
        .wr_valid (wr_valid) ,
        .rd_valid (rd_valid)
    );
    wr_ctrl u_wr_ctrl (
        .clk    (clk)  	   ,
        .rst    (rst)  	   ,
        .wr_en  (wr_valid) ,
        .wr_ptr (wr_ptr)
    );
    rd_ctrl u_rd_ctrl (
        .clk    (clk)	   ,
        .rst    (rst)	   ,
        .rd_en  (rd_valid) ,
        .rd_ptr (rd_ptr)
    );

endmodule

module FIFO_mem(
	input             clk      ,
    input             rst      ,
    input             wr_en    ,
    input             rd_en    ,
	input       [4:0] wr_ptr   ,
    input       [4:0] rd_ptr   ,
    input       [7:0] data_in  ,
    output            full     ,
    output            empty    ,
	output            wr_valid ,
    output            rd_valid ,
    output reg  [7:0] data_out
);
	reg [7:0] mem[0:31];
	reg [5:0] data_cnt;

	assign full  = (data_cnt == 6'd32);
    assign empty = (data_cnt == 0);
	assign wr_valid = wr_en && !full;
    assign rd_valid = rd_en && !empty;

	always @(posedge clk) begin
		if (rst)
			data_cnt <= 0;
		else begin
			case ({wr_valid, rd_valid})
				2'b10: begin
					mem[wr_ptr] <= data_in;
					data_cnt <= data_cnt + 1;
				end
				2'b01: begin
					data_out <= mem[rd_ptr];
					data_cnt <= data_cnt - 1;
				end
				2'b11: begin
					mem[wr_ptr] <= data_in;
                    data_out <= mem[rd_ptr];
				end
				default: begin
					data_cnt <= data_cnt;
					if (rd_en && empty)
						data_out <= 0;
				end
			endcase
		end

	end
endmodule

module wr_ctrl (
	input 			 clk   ,
	input       	 rst   ,
	input 			 wr_en ,
	output reg [4:0] wr_ptr
);
	always @(posedge clk) begin
		if (rst)
			wr_ptr <= 0;
		else if (wr_en)
			wr_ptr <= wr_ptr + 1;
	end
endmodule

module rd_ctrl (
	input 			 clk   ,
	input       	 rst   ,
	input 			 rd_en ,
	output reg [4:0] rd_ptr
);
	always @(posedge clk) begin
		if (rst)
			rd_ptr <= 0;
		else if (rd_en)
			rd_ptr <= rd_ptr + 1;
	end
endmodule