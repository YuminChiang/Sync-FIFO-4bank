module FIFO_sync(
    input             clk     ,
    input             rst     ,
    input             wr_en   ,
    input             rd_en   ,
    input       [7:0] data_in ,
    output            full    ,
    output            empty   ,
    output reg  [7:0] data_out
);
	// Depth: 32 entries
	parameter DEPTH = 32;
	parameter DEPTH_LG2 = 5;
	
	reg [7:0] mem [0:DEPTH-1];
    reg [DEPTH_LG2-1:0] wr_ptr;
    reg [DEPTH_LG2-1:0] rd_ptr;      
    reg [DEPTH_LG2:0]   cnt;
	
	wire wr_valid;
    wire rd_valid;	

	assign full  = (cnt == DEPTH);
    assign empty = (cnt == 0);

    assign wr_valid = wr_en && !full;
    assign rd_valid = rd_en && !empty;
	
	always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr   <= 0;
            rd_ptr   <= 0;
            cnt      <= 0;
            data_out <= 0;
        end
		else begin
            if (wr_valid) begin
                mem[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1;
            end
            if (rd_valid) begin
                data_out <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
            end else if (rd_en && empty)
                data_out <= 8'b0;

            case ({wr_valid, rd_valid})
            	2'b10: cnt <= cnt + 1;
            	2'b01: cnt <= cnt - 1;
            	default: cnt <= cnt;
        	endcase
        end
    end

endmodule