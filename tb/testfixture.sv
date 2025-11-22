`timescale 1ns / 10ps

`define CYCLE       10.0
`define DATA_WIDTH  8
`define DEPTH       32
`define ADDR_WIDTH  5

module testfixture;

    // top interface
    logic clk;
    logic rst;
    logic wr_en;
    logic rd_en;
    logic [`DATA_WIDTH-1:0] data_in;
    logic [`DATA_WIDTH-1:0] data_out;
    logic full;
    logic empty;
    
    // PATTERN GOLDEN MEMORY
    logic [`DATA_WIDTH-1:0] GOLDEN [0:31];

    // Test signal
    int write_count;
    int read_count;
    int err;
    int pass1, pass2, pass3;

    
    // DUT
    FIFO_sync dut (
        .clk      (clk     ),
        .rst      (rst     ),
        .wr_en    (wr_en   ),
        .rd_en    (rd_en   ),
        .data_in  (data_in ),
        .full     (full    ),
        .empty    (empty   ),
        .data_out (data_out)
);

    // clock
    always begin #(`CYCLE/2) clk = ~clk; end

    // initial
    initial begin
        clk     = 0;
        rst     = 1;
        wr_en   = 0;
        rd_en   = 0;
        data_in = 8'd0;
        write_count = 0;
        read_count  = 0;
        err         = 0;
        pass1 = 0;
        pass2 = 0;
        pass3 = 0;

        // Reset
        repeat (5) @(posedge clk);
        rst = 0;
        
        $display("=======================================================");
        $display("==                Simulation Start !!                ==");
        $display("=======================================================");

        // ================= Case 1: Fill FIFO exactly ================
        $display("=======================================================");
        $display("==             Case 1: Fill FIFO exactly             ==");
        $display("=======================================================");
        
        @(posedge clk);
        wr_en = 1;
        data_in = 8'd1;
        repeat (`DEPTH) begin
            @(posedge clk);
            GOLDEN [write_count] = data_in;
            $display("FIFO[%0d] data : %0h", write_count, data_in);

            if (full) begin
                $error("[%0t] ERROR: Before FIFO is full, 'full' flag should be LOW.", $time);
                err++;
            end
            
            data_in++;
            write_count++;
        end
        wr_en = 0;
        data_in     = 0;

        // Check full signal
        @(posedge clk);
        if (!full) begin
            $error("[%0t] ERROR: After FIFO is full, 'full' flag should be HIGH.", $time);
            err++;
        end
        #(`CYCLE/4);
        rd_en = 1;
        @(posedge clk);
        repeat (`DEPTH) begin
            @(posedge clk);
            if(data_out !== GOLDEN [read_count]) begin
                $display("[ERROR] : FIFO[%0d] data : %0h, expect : %0h", read_count, data_out, GOLDEN [read_count]);
                err++;
            end
            if (read_count < 31 && empty) begin
                $error("[ERROR] : Before FIFO is empty , 'empty' flag should be LOW.", $time);
                err++;
            end
            read_count++;
        end
        rd_en = 0;

        // Check empty signal
        @(posedge clk);
        if (!empty) begin
            $error("[%0t] ERROR: After FIFO is empty, 'empty' flag should be HIGH.", $time);
            err++;
        end
        
        // Case 1 Result
        Result(err, 1);
        pass1 = err == 0;

        // ============================================================

        for (int i = 0; i < `DEPTH; i++) begin
            GOLDEN[i] = 8'd0;
        end
        err         = 0;
        write_count = 0;
        read_count  = 0;

        // ===================== Case 2: Overflow =====================
        $display("=======================================================");
        $display("==                 Case 2: Overflow                  ==");
        $display("=======================================================");
        @(posedge clk);
        wr_en = 1;
        data_in = 8'd1;
        
        repeat (`DEPTH+2) begin
            @(posedge clk);
            if(write_count < `DEPTH) begin 
                GOLDEN [write_count] = data_in;
                $display("FIFO[%0d] data : %0h", write_count, data_in); 
                if (full) begin
                    $error("[ERROR] : Before FIFO is full, 'full' flag should be LOW.", $time);
                    err++;
                end
            end
            else begin
                if (!full) begin
                    $error("[ERROR] : After FIFO is full, 'full' flag should be HIGH.", $time);
                    err++;
                end
            end
            data_in++;
            write_count++;
        end
        wr_en = 0;
        data_in     = 0;
        
        // @(posedge clk);
        // if (!full) begin
        //     $error("[ERROR] : After over 32 writes, 'full' flag should be HIGH.", $time);
        //     err++;
        // end

        #(`CYCLE/4);
        rd_en = 1;
        @(posedge clk);
        repeat (`DEPTH) begin
            @(posedge clk);
            if(data_out !== GOLDEN [read_count]) begin
                $display("[READ ERROR] : FIFO[%0d] data : %0h, expect : %0h", read_count, data_out, GOLDEN [read_count]);
                err++;
            end
            if (read_count < 31 && empty) begin
                $error("[ERROR] : Before FIFO is empty, 'empty' flag should be LOW.", $time);
                err++;
            end
            read_count++;
        end
        rd_en = 0;

        // Check empty signal
        @(posedge clk) 
        if (!empty) begin
            $error("[ERROR] : After FIFO is empty, 'empty' flag should be HIGH.", $time);
            err++;
        end

        // Case 2 Result
        Result(err, 2);
        pass2 = err == 0;

        // ============================================================

        for (int i = 0; i < `DEPTH; i++) begin
            GOLDEN[i] = 8'd0;
        end
        err         = 0;
        write_count = 0;
        read_count  = 0;

        // ==================== Case 3: Underflow =====================
        $display("=======================================================");
        $display("==                 Case 3: Underflow                 ==");
        $display("=======================================================");
        @(posedge clk);
        wr_en = 1;
        data_in = 8'd1;
        
        repeat (`DEPTH-2) begin
            @(posedge clk);
            if(write_count < `DEPTH) begin 
                GOLDEN [write_count] = data_in;
                $display("FIFO[%0d] data : %0h", write_count, data_in); 
                if (full) begin
                    $error("[ERROR] : Before FIFO is full, 'full' flag should be LOW.", $time);
                    err++;
                end
            end
            data_in     = data_in + 1;
            write_count = write_count + 1;
        end
        wr_en = 0;
        
        @(posedge clk);
        if (full) begin
            $error("[ERROR] : Before FIFO is full, 'full' flag should be LOW.", $time);
            err++;
        end

        #(`CYCLE/4);
        rd_en = 1;
        @(posedge clk);
        repeat (`DEPTH) begin
            @(posedge clk);

            if (data_out !== GOLDEN [read_count]) begin
                $display("[READ ERROR] : FIFO[%0d] data : %0h, expect : %0h", read_count, data_out, GOLDEN [read_count]);
                err++;
            end

            if (read_count >= 29) begin
                if(!empty) begin
                    $error("[ERROR] : After FIFO is empty, 'empty' flag should be HIGH.", $time);
                    err++;
                end
            end
            else begin
                if(empty) begin
                    $error("[ERROR] : Before FIFO is empty, 'empty' flag should be LOW.", $time);
                    err++;
                end
            end
            
            read_count = read_count + 1;
        end
        rd_en = 0;
        
        // Check empty signal
        @(posedge clk)
        if (!empty) begin
            $error("[ERROR] : After FIFO is empty, 'empty' flag should be HIGH.", $time);
            err++;
        end

        // Case 3 Result
        Result(err, 3);
        pass3 = err == 0;

        repeat (5) @(negedge clk);
        Final_Result(pass1, pass2, pass3);

        // End Simulation
        repeat (10) @(negedge clk);
        $finish;
    end

    task Result(input integer err, case_num);begin
        if(err == 0) begin
            $display("=======================================================");
            $display("==                Congratulations !!                 ==");
            $display("==            Case %0d Simulation PASS !!              ==", case_num);
            $display("=======================================================");
        end
        else begin
            $display("=======================================================");
            $display("==  There are %0d errors, please check your design.  ==", err);
            $display("=======================================================");
        end
    end 
    endtask  

    task Final_Result(input integer pass1, pass2, pass3);begin
        if(pass1 && pass2 && pass3 ) begin
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