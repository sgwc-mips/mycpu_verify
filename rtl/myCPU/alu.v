module alu(
  input         clk,
  input         reset,
  input  [21:0] alu_op,
  input  [31:0] alu_src1,
  input  [31:0] alu_src2,
  output        exe_complete,
  output [31:0] alu_result
);

wire op_add;   //¼Ó·¨²Ù×÷
wire op_sub;   //¼õ·¨²Ù×÷
wire op_slt;   //ÓÐ·ûºÅ±È½Ï£¬Ð¡ÓÚÖÃÎ»
wire op_sltu;  //ÎÞ·ûºÅ±È½Ï£¬Ð¡ÓÚÖÃÎ»
wire op_and;   //°´Î»Óë
wire op_nor;   //°´Î»»ò·Ç
wire op_or;    //°´Î»»ò
wire op_xor;   //°´Î»Òì»ò
wire op_sll;   //Âß¼­×óÒÆ
wire op_srl;   //Âß¼­ÓÒÒÆ
wire op_sra;   //ËãÊõÓÒÒÆ
wire op_lui;   //Á¢¼´ÊýÖÃÓÚ¸ß°ë²¿·Ö

wire op_mult;
wire op_multu;
wire op_div;
wire op_divu;

wire op_mfhi;
wire op_mflo;
wire op_mthi;
wire op_mtlo;

// control code decomposition
assign op_add   = alu_op[ 0];
assign op_sub   = alu_op[ 1];
assign op_slt   = alu_op[ 2];
assign op_sltu  = alu_op[ 3];
assign op_and   = alu_op[ 4];
assign op_nor   = alu_op[ 5];
assign op_or    = alu_op[ 6];
assign op_xor   = alu_op[ 7];
assign op_sll   = alu_op[ 8];
assign op_srl   = alu_op[ 9];
assign op_sra   = alu_op[10];
assign op_lui   = alu_op[11];

assign op_mult  = alu_op[12];
assign op_multu = alu_op[13];
assign op_div   = alu_op[14];
assign op_divu  = alu_op[15];

assign op_mfhi  = alu_op[16];
assign op_mflo  = alu_op[17];
assign op_mthi  = alu_op[18];
assign op_mtlo  = alu_op[19];


wire [31:0] add_sub_result; 
wire [31:0] slt_result; 
wire [31:0] sltu_result;
wire [31:0] and_result;
wire [31:0] nor_result;
wire [31:0] or_result;
wire [31:0] xor_result;
wire [31:0] lui_result;
wire [31:0] sll_result; 
wire [63:0] sr64_result; 
wire [31:0] sr_result; 

wire [63:0] mult_result;
wire [63:0] multu_result; 
wire [63:0] div_result;
wire [63:0] divu_result;

wire [31:0] mfhi_result;
wire [31:0] mflo_reslut;

// 32-bit adder
wire [31:0] adder_a;
wire [31:0] adder_b;
wire        adder_cin;
wire [31:0] adder_result;
wire        adder_cout;

assign adder_a   = alu_src1;
assign adder_b   = (op_sub | op_slt | op_sltu) ? ~alu_src2 : alu_src2;
assign adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1      : 1'b0;
assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;

// ADD, SUB result
assign add_sub_result = adder_result;  

// SLT result
assign slt_result[31:1] = 31'b0;
assign slt_result[0]    = (alu_src1[31] & ~alu_src2[31])
                        | ((alu_src1[31] ~^ alu_src2[31]) & adder_result[31]);

// SLTU result
assign sltu_result[31:1] = 31'b0;
assign sltu_result[0]    = ~adder_cout;

// bitwise operation
assign and_result = alu_src1 & alu_src2;
assign or_result  = alu_src1 | alu_src2;
assign nor_result = ~or_result;
assign xor_result = alu_src1 ^ alu_src2;
assign lui_result = {alu_src2[15:0], 16'b0};

// SLL result 
assign sll_result = alu_src2 << alu_src1[4:0];

// SRL, SRA result
assign sr64_result = {{32{op_sra & alu_src2[31]}}, alu_src2[31:0]} >> alu_src1[4:0];
assign sr_result   = sr64_result[31:0];

// mult & div
reg [31:0]  reg_hi, reg_lo;

assign mfhi_result = reg_hi;
assign mflo_reslut = reg_lo;

reg div_complete, divu_complete;
reg mult_complete, multu_complete;

reg div_read_complete, divu_read_complete;

wire  div_dividend_tready;
reg   div_dividend_tvalid;
wire  div_divisor_tready;
reg   div_divisor_tvalid;
wire  div_dout_tvalid;

wire  divu_dividend_tready;
reg   divu_dividend_tvalid;
wire  divu_divisor_tready;
reg   divu_divisor_tvalid;
wire  divu_dout_tvalid;

always @(posedge clk) begin
  if(reset) begin
      reg_hi        <= 0;
      reg_lo        <= 0;
  end
  
  else if(op_mthi) begin
      reg_hi <= alu_src1;
  end
  else if(op_mtlo) begin
      reg_lo <= alu_src1;
  end
  else if(op_mult) begin
      {reg_hi, reg_lo} <= mult_result;
  end  
  else if(op_multu) begin
      {reg_hi, reg_lo} <= multu_result;
  end

  else if(op_div) begin
      if(div_dout_tvalid) begin
        {reg_lo, reg_hi} <= div_result;
      end
  end
  else if(op_divu) begin
      if(divu_dout_tvalid) begin
        {reg_lo, reg_hi} <= divu_result;
      end
  end
end

always @(posedge clk) begin
  if(reset) begin
    div_complete   <= 0;
    divu_complete  <= 0;
    mult_complete  <= 0;
    multu_complete <= 0;
  end
  else begin
    if(op_div & div_dout_tvalid) begin
      div_complete <= 1;
    end
    else begin
      div_complete <= 0;
    end

    if(op_divu & divu_dout_tvalid) begin
      divu_complete <= 1;
    end
    else begin
      divu_complete <= 0;
    end

    if(op_mult) begin
      mult_complete <= 1;
    end
    else begin
      mult_complete <= 0;
    end

    if(op_multu) begin
      multu_complete <= 1;
    end
    else begin
      multu_complete <= 0;
    end
  end
end

assign multu_result  = alu_src1 * alu_src2;
assign mult_result   = $signed(alu_src1) * $signed(alu_src2);

always @(posedge clk) begin
  if(reset) begin
    div_read_complete  <= 1'b0;
    divu_read_complete <= 1'b0;
  end
  else begin
    if(div_dividend_tvalid  & div_dividend_tready  & op_div) begin
      div_read_complete  <= 1'b1;
    end
    else if(div_complete) begin
      div_read_complete  <= 1'b0;
    end

    if(divu_dividend_tvalid & divu_dividend_tready & op_divu) begin
      divu_read_complete <= 1'b1;
    end
    else if(divu_complete) begin
      divu_read_complete <= 1'b0;
    end
  end
end


assign exe_complete = op_div  ? div_complete   :
                      op_divu ? divu_complete  :
                      op_mult ? mult_complete  :
                      op_multu? multu_complete : 
                                1'b1;

always @(posedge clk) begin
   if(reset) begin
     div_dividend_tvalid <= 1'b1;
     div_divisor_tvalid  <= 1'b1;
   end
end

always @(posedge clk) begin
    div_dividend_tvalid   <= ~(div_dividend_tready & op_div & div_dividend_tvalid);
    div_divisor_tvalid    <= ~(div_divisor_tready  & op_div & div_divisor_tvalid );
end

mydiv mydiv(.aclk                   (clk),
            .s_axis_dividend_tdata  (alu_src1),
            .s_axis_dividend_tready (div_dividend_tready),
            .s_axis_dividend_tvalid (div_dividend_tvalid & op_div & ~div_read_complete),
            .s_axis_divisor_tdata   (alu_src2),
            .s_axis_divisor_tready  (div_divisor_tready),
            .s_axis_divisor_tvalid  (div_divisor_tvalid  & op_div & ~div_read_complete),
            .m_axis_dout_tdata      (div_result),
            .m_axis_dout_tvalid     (div_dout_tvalid)
            );

always @(posedge clk) begin
  if(reset) begin
    divu_dividend_tvalid <= 1'b1;
    divu_divisor_tvalid  <= 1'b1;
  end
end

always @(posedge clk) begin
    divu_dividend_tvalid   <= ~(divu_dividend_tready & op_divu & divu_dividend_tvalid);
    divu_divisor_tvalid    <= ~(divu_divisor_tready  & op_divu & divu_divisor_tvalid );
end

mydivu mydivu(.aclk                   (clk),
              .s_axis_dividend_tdata  (alu_src1),
              .s_axis_dividend_tready (divu_dividend_tready),
              .s_axis_dividend_tvalid (divu_dividend_tvalid & op_divu & ~divu_read_complete),
              .s_axis_divisor_tdata   (alu_src2),
              .s_axis_divisor_tready  (divu_divisor_tready),
              .s_axis_divisor_tvalid  (divu_divisor_tvalid  & op_divu & ~divu_read_complete),
              .m_axis_dout_tdata      (divu_result),
              .m_axis_dout_tvalid     (divu_dout_tvalid)
              );

// final result mux
assign alu_result = ({32{op_add|op_sub}} & add_sub_result)
                  | ({32{op_slt       }} & slt_result)
                  | ({32{op_sltu      }} & sltu_result)
                  | ({32{op_and       }} & and_result)
                  | ({32{op_nor       }} & nor_result)
                  | ({32{op_or        }} & or_result)
                  | ({32{op_xor       }} & xor_result)
                  | ({32{op_lui       }} & lui_result)
                  | ({32{op_sll       }} & sll_result)
                  | ({32{op_srl|op_sra}} & sr_result)
                  | ({32{op_mfhi      }} & mfhi_result)
                  | ({32{op_mflo      }} & mflo_reslut);

endmodule
