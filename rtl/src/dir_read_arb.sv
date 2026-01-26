// Author: Ho Tin Hung

module dir_read_arb #(
  // parameter int unsigned NumTagBankPerCtrl = 2,
  parameter int unsigned NumWays = 4,

  parameter type hpdcache_dir_addr_t   = logic,
  parameter type hpdcache_way_vector_t = logic,
  parameter type hpdcache_dir_entry_t  = logic
)(
  input logic clk_i,
  input logic rst_ni,

  input  hpdcache_dir_addr_t                           comb_dir_addr_i,
  input  hpdcache_way_vector_t                         comb_dir_cs_i,
  input  hpdcache_way_vector_t                         comb_dir_we_i,
  input  hpdcache_dir_entry_t            [NumWays-1:0] comb_dir_wentry_i,

  input  logic                                         coherence_req_i,
  input  hpdcache_dir_addr_t                           coherence_dir_addr_i,
  input  hpdcache_way_vector_t                         coherence_dir_cs_i,
  input  hpdcache_way_vector_t                         coherence_dir_we_i,
  input  hpdcache_dir_entry_t            [NumWays-1:0] coherence_dir_wentry_i,

  output hpdcache_dir_addr_t                           dir_addr_o,
  output hpdcache_way_vector_t                         dir_cs_o,
  output hpdcache_way_vector_t                         dir_we_o,
  output hpdcache_dir_entry_t            [NumWays-1:0] dir_wentry_o
);

  typedef struct packed {
    hpdcache_dir_addr_t                           dir_addr;
    hpdcache_way_vector_t                         dir_cs;
    hpdcache_way_vector_t                         dir_we;
    hpdcache_dir_entry_t [NumWays-1:0] dir_wentry;
  } dir_req_pack_t;

  dir_req_pack_t comb_req_pack, coherence_req_pack, final_req_pack;
  dir_req_pack_t [1:0] req_pack_combined;
  logic req_valid;

  assign comb_req_pack.dir_addr    = comb_dir_addr_i;
  assign comb_req_pack.dir_cs      = comb_dir_cs_i;
  assign comb_req_pack.dir_we      = comb_dir_we_i;
  assign comb_req_pack.dir_wentry  = comb_dir_wentry_i;

  assign coherence_req_pack.dir_addr    = coherence_dir_addr_i;
  assign coherence_req_pack.dir_cs      = coherence_dir_cs_i;
  assign coherence_req_pack.dir_we      = coherence_dir_we_i;
  assign coherence_req_pack.dir_wentry  = coherence_dir_wentry_i;

  assign req_pack_combined[0] = comb_req_pack;
  assign req_pack_combined[1] = coherence_req_pack;

  assign dir_addr_o   = final_req_pack.dir_addr;
  assign dir_cs_o     = final_req_pack.dir_cs;
  assign dir_we_o     = final_req_pack.dir_we;
  assign dir_wentry_o = final_req_pack.dir_wentry;

  assign req_valid = (comb_dir_cs_i != '0) || coherence_req_i;

  rr_arb_tree #(
    .NumIn     (2),
    .DataType  (dir_req_pack_t)
    // .AxiVldRdy (1'b1)
  ) i_dir_ctrl_rr_arb (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),
    .flush_i (1'b0),
    .rr_i    (1'b1),
    .req_i   (req_valid),  // valid_i
    .gnt_o   (),  // ready_o
    .data_i  (req_pack_combined),
    .req_o   (),            // valid_o
    .gnt_i   (1'b1),                           // ready_i
    .data_o  (final_req_pack),
    .idx_o   ()
  );

  // dir_req_pack_t comb_req_pack_push, comb_req_pack_pop;
  // logic latch_comb_req, serve_pend_req;
  // logic fifo_full, fifo_empty;

  // assign comb_req_pack_push.dir_addr    = comb_dir_addr_i;
  // assign comb_req_pack_push.dir_cs      = comb_dir_cs_i;
  // assign comb_req_pack_push.dir_we      = comb_dir_we_i;
  // assign comb_req_pack_push.dir_wentry  = comb_dir_wentry_i;

  // assign serve_pend_req = (coherence_req_i == '0) && (!fifo_empty);

  // always_comb begin
  //   if(coherence_req_i) begin
  //     // latch_comb_req = !(comb_dir_cs_i == '0);
  //     if(comb_dir_cs_i != '0) begin
  //       latch_comb_req = !((comb_dir_addr_i == coherence_dir_addr_i)  &&
  //                           (comb_dir_cs_i == coherence_dir_cs_i)     &&
  //                           (comb_dir_we_i == coherence_dir_we_i));
  //     end else begin
  //       // latch_comb_req = !(comb_dir_cs_i == '0);
  //     end
  //     // Prioritize coherence request to output
  //     dir_addr_o   = coherence_dir_addr_i;
  //     dir_cs_o     = coherence_dir_cs_i;
  //     dir_we_o     = coherence_dir_we_i;
  //     dir_wentry_o = coherence_dir_wentry_i;
  //   end else if (comb_dir_cs_i != '0) begin
  //     if(fifo_empty) begin
  //       // comb request coming in with empty fifo, fall through
  //       dir_addr_o   = comb_dir_addr_i;
  //       dir_cs_o     = comb_dir_cs_i;
  //       dir_we_o     = comb_dir_we_i;
  //       dir_wentry_o = comb_dir_wentry_i;
  //       latch_comb_req = 1'b0;
  //     end else begin
  //       // otherwise serve buffered req first and buffer current req
  //       dir_addr_o   = comb_req_pack_pop.dir_addr;
  //       dir_cs_o     = comb_req_pack_pop.dir_cs;
  //       dir_we_o     = comb_req_pack_pop.dir_we;
  //       dir_wentry_o = comb_req_pack_pop.dir_wentry;
  //       latch_comb_req = 1'b1;
  //     end
  //   end else begin
  //     // No incoming requests, serve buffered req if any
  //     dir_addr_o   = comb_req_pack_pop.dir_addr;
  //     dir_cs_o     = comb_req_pack_pop.dir_cs;
  //     dir_we_o     = comb_req_pack_pop.dir_we;
  //     dir_wentry_o = comb_req_pack_pop.dir_wentry;
  //     latch_comb_req = 1'b0; 
  //   end
  // end

  // fifo_v3 #(
  //   .FALL_THROUGH      (1'b0),
  //   .DATA_WIDTH        ($bits(dir_req_pack_t)),
  //   .DEPTH             (64),
  //   .dtype             (dir_req_pack_t)
  // ) i_comb_req_buf (
  //   .clk_i        (clk_i),
  //   .rst_ni       (rst_ni),
  //   .flush_i      (1'b0),
  //   .testmode_i   (1'b0),
  //   .full_o       (fifo_full),
  //   .empty_o      (fifo_empty),
  //   .usage_o      (),
  //   .data_i       (comb_req_pack_push),
  //   .push_i       (latch_comb_req),
  //   .data_o       (comb_req_pack_pop),
  //   .pop_i        (serve_pend_req)
  // );

endmodule