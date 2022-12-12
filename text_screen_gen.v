module text_screen_gen
(
	input clk,reset_n,
	input video_on,
	input [2:0] btn,
	input [6:0] sw,
	input [9:0] pixel_x,pixel_y,
	output reg [2:0] text_rgb
);

//signal declaration
//font rom
wire [10:0] rom_addr;
wire [6:0] char_addr;
wire [3:0] row_addr;
wire [2:0] bit_addr;
wire [7:0] font_word;
wire font_bit;
//tile ram
wire we;
wire [11:0] rd_addr,wr_addr;
wire [6:0] din,dout;
localparam MAX_X=80,MAX_Y=30;
//cursor
reg [6:0] cur_x_reg=7'b0;
wire [6:0] cur_x_next;
reg [4:0] cur_y_reg=5'b0;
wire [4:0] cur_y_next;
wire move_x_tick,move_y_tick,cursor_on;
//delayed pixel count
reg [9:0] pixel_x_reg_1=0,pixel_x_reg_2=0;
reg [9:0] pixel_y_reg_1=0,pixel_y_reg_2=0;
//object output signals
wire [2:0] font_rgb,font_rev_rgb;
//body

db_fsm db_fsm_inst_0
(.clk(clk), .reset_n(reset_n), .sw(!btn[0]), 
	 .db_tick(move_x_tick));
db_fsm db_fsm_inst_1
(.clk(clk), .reset_n(reset_n), .sw(!btn[1]), 
	 .db_tick(move_y_tick));
db_fsm db_fsm_inst_2
(.clk(clk), .reset_n(reset_n), .sw(!btn[2]), 
	 .db_tick(we));

//font rom
font_rom font_rom_inst 
(.clk(clk), .addr(rom_addr), .data(font_word));
//tile ram
dual_port_ram dual_port_ram_inst(
	.clock(clk), .data(din),
	.rdaddress(rd_addr),.wraddress(wr_addr), 
	.wren(we), .q(dout));
// blk_mem_gen_0 video_ram
//       (.clka(clk), .clkb(clk), .wea(we), .addra(wr_addr), .addrb(rd_addr),
//        .dina(din), .doutb(dout));
//registers
always @(posedge clk)
begin
	if(~reset_n)
	begin
		cur_x_reg <= 0;
		cur_y_reg <= 0;
		pixel_x_reg_1 <= 0;
		pixel_x_reg_2 <= 0;
		pixel_y_reg_1 <= 0;
		pixel_y_reg_2 <= 0;		
	end
	else
	begin
		cur_x_reg <= cur_x_next;
		cur_y_reg <= cur_y_next;
		pixel_x_reg_1 <= pixel_x;
		pixel_x_reg_2 <= pixel_x_reg_1;
		pixel_y_reg_1 <= pixel_y;
		pixel_y_reg_2 <= pixel_y_reg_1;
	end
end
//tile ram write
assign wr_addr = {cur_y_reg,cur_x_reg};
assign din = sw;
//tile ram read
assign rd_addr = {pixel_y[8:4],pixel_x[9:3]};
assign char_addr = dout;
//font rom
assign row_addr = pixel_y[3:0];
assign rom_addr = {char_addr, row_addr};
//use delayed coordinates to select bits
assign bit_addr = pixel_x_reg_2[2:0];
assign font_bit = font_word[~bit_addr];
//new cursor position
assign cur_x_next = (move_x_tick && cur_x_reg == MAX_X-1)? 7'b0: ((move_x_tick)? cur_x_reg + 1 
: cur_x_reg);
assign cur_y_next = (move_y_tick && cur_y_reg == MAX_Y-1)? 5'b0: ((move_y_tick)? cur_y_reg + 1 
: cur_y_reg);

//object signals
assign font_rgb = (font_bit)? 3'b010 : 3'b000;
assign font_rev_rgb = (font_bit)? 3'b000:3'b010;
//use delayed signals for comparsion
assign cursor_on = (pixel_x_reg_2[9:3] ==cur_x_reg) &&
(pixel_y_reg_2[8:4] == cur_y_reg);

always @*
begin
	if(~video_on)
		text_rgb = 3'b000;
	else 
		if(cursor_on)
			text_rgb = font_rev_rgb;
		else
			text_rgb = font_rgb;
end


endmodule