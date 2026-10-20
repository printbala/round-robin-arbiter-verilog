// Self-checking testbench for rr_arbiter.
// Checks: grant is one-hot and only to a requester, matches a reference
// model (rotating priority), and fairness under continuous contention.
`timescale 1ns/1ps
module tb_rr_arbiter;
    localparam N = 4;
    reg clk = 0, rst_n = 0;
    reg  [N-1:0] req = 0;
    wire [N-1:0] grant;
    rr_arbiter #(N) dut (.clk(clk), .rst_n(rst_n), .req(req), .grant(grant));
    always #5 clk = ~clk;

    // ---------- reference model ----------
    integer ref_last = N-1, errors = 0, k, j;
    reg [N-1:0] exp_g;
    integer exp_win;
    task model;
        begin
            exp_g = 0; exp_win = ref_last;
            for (k = 1; k <= N; k = k + 1) begin
                j = (ref_last + k) % N;
                if (req[j] && exp_g == 0) begin exp_g[j] = 1; exp_win = j; end
            end
        end
    endtask

    // check on every cycle, shortly after inputs change; update model on clock edge
    always @(negedge clk) if (rst_n) begin
        #1; model;
        if (grant !== exp_g) begin
            errors = errors + 1; $display("[%0t] req=%b exp=%b got=%b", $time, req, exp_g, grant); end
        if ((grant & (grant - 1)) != 0) begin errors = errors + 1; $display("[%0t] grant not one-hot", $time); end
        if ((grant & ~req) != 0)        begin errors = errors + 1; $display("[%0t] granted non-requester", $time); end
    end
    always @(posedge clk) if (!rst_n) ref_last = N-1; else begin model; if (|exp_g) ref_last = exp_win; end

    // ---------- fairness counters ----------
    integer cnt [0:N-1];
    integer n;
    always @(posedge clk) if (rst_n) for (n = 0; n < N; n = n + 1) if (grant[n]) cnt[n] = cnt[n] + 1;

    integer i;
    initial begin
        for (n = 0; n < N; n = n + 1) cnt[n] = 0;
        repeat (3) @(negedge clk); rst_n = 1;

        $display("T1: no requests -> no grant");
        @(negedge clk); req = 4'b0000;
        repeat (2) @(negedge clk);

        $display("T2: single requesters");
        for (i = 0; i < N; i = i + 1) begin @(negedge clk); req = 1 << i; end
        @(negedge clk); req = 0;

        $display("T3: all request continuously -> grants must rotate 0,1,2,3,...");
        for (n = 0; n < N; n = n + 1) cnt[n] = 0;
        @(negedge clk); req = 4'b1111;
        repeat (40) @(negedge clk);
        for (n = 0; n < N; n = n + 1)
            if (cnt[n] < 9 || cnt[n] > 11) begin errors = errors + 1; $display("UNFAIR: req%0d got %0d/40", n, cnt[n]); end
        $display("    grant counts over 40 cycles: %0d %0d %0d %0d", cnt[0], cnt[1], cnt[2], cnt[3]);

        $display("T4: two persistent requesters share equally, third joins late");
        @(negedge clk); req = 4'b0101;
        repeat (10) @(negedge clk);
        req = 4'b0111;
        repeat (10) @(negedge clk);

        $display("T5: random requests");
        for (i = 0; i < 2000; i = i + 1) begin @(negedge clk); req = $random; end

        req = 0; repeat (3) @(negedge clk);
        if (errors == 0) $display("RESULT: PASS - all checks passed");
        else             $display("RESULT: FAIL - %0d errors", errors);
        $finish;
    end
endmodule
