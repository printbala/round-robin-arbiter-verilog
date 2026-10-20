// Round-robin arbiter with rotating priority.
// Priority starts at the requester AFTER the last one granted, so a
// requester that keeps requesting waits at most N-1 grants (no starvation).
module rr_arbiter #(
    parameter N = 4
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [N-1:0] req,
    output reg  [N-1:0] grant     // one-hot (or zero if no request)
);
    localparam W = $clog2(N);

    reg [W-1:0] last;             // index of most recent winner
    reg [W-1:0] win;              // index of current winner
    integer i, idx;

    // Combinational: scan requesters starting just after 'last'
    always @* begin
        grant = {N{1'b0}};
        win   = last;
        for (i = 1; i <= N; i = i + 1) begin
            idx = (last + i) % N;
            if (req[idx] && grant == {N{1'b0}}) begin
                grant[idx] = 1'b1;
                win = idx;
            end
        end
    end

    // Sequential: rotate priority only when a grant is issued
    always @(posedge clk) begin
        if (!rst_n)        last <= N-1;   // so requester 0 has top priority first
        else if (|grant)   last <= win;
    end
endmodule
