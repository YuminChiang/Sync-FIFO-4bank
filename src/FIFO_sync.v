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

/*
	Write Your Design Here ~
*/
    // --- ???? ---
    // FIFO ??? 32?????? 5 bits (2^5 = 32)
    parameter DEPTH_LG2 = 5; 
    parameter DEPTH     = 32;

    // --- ??????? ---
    reg [7:0] MEM [0:DEPTH-1];          // 32x8 ?????
    reg [DEPTH_LG2-1:0] w_ptr;          // ???? (0-31)
    reg [DEPTH_LG2-1:0] r_ptr;          // ???? (0-31)
    reg [DEPTH_LG2:0]   cnt;            // ??? (??? 0-32??? 6 bits)

    // --- ???? (Combinational) ---
    // ???????? (32) ???
    assign full  = (cnt == DEPTH);
    // ?????? 0 ???
    assign empty = (cnt == 0);

    // --- ???? (Sequential) ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            w_ptr    <= 0;
            r_ptr    <= 0;
            cnt      <= 0;
            data_out <= 0;
        end
        else begin
            // --- ???? ---
            // ??????? ? FIFO ???
            if (wr_en && !full) begin
                MEM[w_ptr] <= data_in;
                w_ptr <= w_ptr + 1;
            end

            // --- ???? ---
            // ??????? ? FIFO ???
            if (rd_en && !empty) begin
                // ????: Read latency is one clock cycle.
                // ??????????????? data_out register
                data_out <= MEM[r_ptr];
                r_ptr <= r_ptr + 1;
            end

            // --- ??????? ---
            // ?? 1: ???????????? -> ??? +1
            if ((wr_en && !full) && !(rd_en && !empty)) begin
                cnt <= cnt + 1;
            end
            // ?? 2: ???????????? -> ??? -1
            else if ((rd_en && !empty) && !(wr_en && !full)) begin
                cnt <= cnt - 1;
            end
            // ?? 3: ???? (Concurrent R/W) -> ?????
            // ?? 4: ??? -> ?????
            else begin
                cnt <= cnt;
            end
        end
    end


endmodule