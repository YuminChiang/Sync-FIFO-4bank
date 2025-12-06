`timescale 1ns / 10ps

`define CYCLE       25.0
`define DATA_WIDTH  8
`define DEPTH       32
`define PAT_DEPTH   10000
`define GOLDEN_DEPTH 3725
`define BANK_NUM    4

module testfixture_bank;

    // top interface
    logic clk;
    logic rst;
    logic wr_en_M0, wr_en_M1;
    logic rd_en_M0, rd_en_M1;
    logic [`DATA_WIDTH-1:0] data_in_M0, data_in_M1;
    logic [`DATA_WIDTH-1:0] data_out_M0, data_out_M1;
    logic [$clog2(`BANK_NUM)-1:0] rd_id_M0, rd_id_M1;
    logic valid_M0, valid_M1;
    
    // PATTERN GOLDEN MEMORY
    logic [23:0] pattern[`PAT_DEPTH-1:0];
    logic [`DATA_WIDTH:0] golden[`GOLDEN_DEPTH-1:0];
    logic [`DATA_WIDTH:0] monitor[`GOLDEN_DEPTH-1:0];

    // Test signal
    int cycle_cnt;
    int err;
    int pass;
    int monitor_cnt;

    
    // DUT
    FourBankFIFO dut(
        .clk        (clk        ),
        .rst        (rst        ),
        .wr_en_M0   (wr_en_M0   ),
        .data_in_M0 (data_in_M0 ),
        .rd_en_M0   (rd_en_M0   ),
        .rd_id_M0   (rd_id_M0   ),
        .wr_en_M1   (wr_en_M1   ),
        .data_in_M1 (data_in_M1 ),
        .rd_en_M1   (rd_en_M1   ),
        .rd_id_M1   (rd_id_M1   ),
        .data_out_M0(data_out_M0),
        .data_out_M1(data_out_M1),
        .valid_M0   (valid_M0   ),
        .valid_M1   (valid_M1   )
    );

    // clock
    always begin #(`CYCLE/2) clk = ~clk; end

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            cycle_cnt <= 'd0;
        end
        else begin
            cycle_cnt <= cycle_cnt + 'd1;
        end
    end

    // initial
    initial begin
        clk         = 0;
        rst         = 1;
        wr_en_M0    = 0;
        rd_en_M0    = 0;
        wr_en_M1    = 0;
        rd_en_M1    = 0;
        data_in_M0  = 8'd0;
        data_in_M1  = 8'd0;
        rd_en_M0    = 2'd0;
        rd_en_M1    = 2'd0;
        err         = 0;
        pass        = 0;
        monitor_cnt = 0;
        for(int i=0; i<`GOLDEN_DEPTH; i++) begin
            monitor[i] <= 'dx;
        end

        // Reset
        repeat (5) @(posedge clk);
        rst = 0;

        $readmemh("./dat/fifo_sim.hex", pattern);
        $readmemh("./dat/golden.hex", golden);

        for(int i=0; i<`PAT_DEPTH; i++) begin
            @(posedge clk) begin
                wr_en_M0 <= pattern[i][23];
                rd_en_M0 <= pattern[i][22];
                wr_en_M1 <= pattern[i][21];
                rd_en_M1 <= pattern[i][20];
                data_in_M0 <= pattern[i][19:12];
                data_in_M1 <= pattern[i][11:4];
                rd_id_M0 <= pattern[i][3:2];
                rd_id_M1 <= pattern[i][1:0];
            end
            @(negedge clk) begin
                if(valid_M0 || valid_M1) begin
                    monitor[monitor_cnt] <= (valid_M0)? {data_out_M0, 1'b0} : {data_out_M1, 1'b1};
                    monitor_cnt <= monitor_cnt + 1;
                end
            end
        end

        @(negedge clk) begin
            if(valid_M0 || valid_M1) begin
                monitor[monitor_cnt] <= (valid_M0)? {data_out_M0, 1'b0} : {data_out_M1, 1'b1};
                monitor_cnt <= monitor_cnt + 1;
            end
        end

        #(`CYCLE);
        for(int i=0; i<`GOLDEN_DEPTH; i++) begin
            if(monitor[i] !== golden[i]) begin
                $display("FAIL: Monitor[%2d]: %4h, expect: %4h", i, monitor[i], golden[i]);
                err++;
            end
            else begin
                $display("PASS: Monitor[%2d]: %4h, expect: %4h", i, monitor[i], golden[i]);
            end
        end

        Result(err);
        pass = (err == 0);

        repeat (5) @(negedge clk);
        Final_Result(pass);

        // End Simulation
        repeat (10) @(negedge clk);
        $finish;
    end

    task Result(input integer err);begin
        if(err == 0) begin
            $display("=======================================================");
            $display("==                Congratulations !!                 ==");
            $display("==                Simulation PASS !!                 ==");
            $display("=======================================================");
        end
        else begin
            $display("=======================================================");
            $display("==  There are %0d errors, please check your design.  ==", err);
            $display("=======================================================");
        end
    end 
    endtask  

    task Final_Result(input integer pass);begin
        if(pass) begin
            $display("=======================================================");
            $display("   ( \\_._/ )                                          ");
            $display("   ( o ω o )          Congratulations !!               ");
            $display(" o-(       )-o        Simulation PASS !!               ");
            $display("     ''  ''                                            ");
            $display("=======================================================");
        end
        else begin
            $display("=======================================================");
            $display("   ( \\_._/ )                                          ");
            $display("   ( x ω x )          OOPS !!                          ");
            $display(" o-(       )-o        Simulation Failed !!             ");
            $display("     ''  ''                                            ");
            $display("=======================================================");
        end
    end 
    endtask

endmodule