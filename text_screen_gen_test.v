module text_screen_gen_test
(
	input clk,reset_n,
	input [2:0] btn,
	output vga_hsync,vga_vsync,
	output [2:0] vga_rgb
);

//signal declarations
wire [11:0] pixel_x,pixel_y;
wire video_on;
reg [2:0] rgb_reg;
wire [2:0] rgb_next;

//body
 vga_sync vga_sync_inst
(.clk(clk), .rst_n(reset_n), .hsync(vga_hsync), .vsync(vga_vsync), .pixel_x(pixel_x), .pixel_y(pixel_y),
	.video_on(video_on));

text_screen_gen text_screen_gen_inst
(	.clk(clk),.reset_n(reset_n),
	.video_on(video_on),
	.btn(btn),
	.sw(7'd70),
	.pixel_x(pixel_x),.pixel_y(pixel_y),
	.text_rgb(rgb_next)
);

always @(posedge clk or negedge reset_n)
begin
	if(~reset_n)
		rgb_reg <= 0;
	else
		rgb_reg <= rgb_next;
end
assign vga_rgb = rgb_reg;

endmodule