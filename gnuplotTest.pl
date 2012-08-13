use Graphics::GnuplotIF qw(GnuplotIF);

#http://search.cpan.org/~mehner/Graphics-GnuplotIF/lib/Graphics/GnuplotIF.pm

my  @x  = ( -2, -1.50, -1, -0.50,  0,  0.50,  1, 1.50, 2 ); # x values
my  @y1 = (  4,  2.25,  1,  0.25,  0,  0.25,  1, 2.25, 4 ); # function 1
my  @y2 = (  2,  0.25, -1, -1.75, -2, -1.75, -1, 0.25, 2 ); # function 2

my  $plot1 = Graphics::GnuplotIF->new(title => "line", style => "points");

$plot1->gnuplot_plot_y( \@x );                # plot 9 points over 0..8

$plot1->gnuplot_pause(5 );                     # hit RETURN to continue

$plot1->gnuplot_set_title( "parabola" );      # new title
$plot1->gnuplot_set_style( "lines" );         # new line style

$plot1->gnuplot_plot_xy( \@x, \@y1, \@y2 );   # plot 1: y1, y2 over x
$plot1->gnuplot_plot_many( \@x, \@y1, \@x, \@y2 ); # plot 1: y1 - x, y2 - x

my  $plot2  = Graphics::GnuplotIF->new;       # new plot object

$plot2->gnuplot_set_xrange(  0, 4 );          # set x range
$plot2->gnuplot_set_yrange( -2, 2 );          # set y range
$plot2->gnuplot_cmd( "set grid" );            # send a gnuplot command
$plot2->gnuplot_plot_equation(                # 3 equations in one plot
	"y1(x) = sin(x)",
	"y2(x) = cos(x)",
	"y3(x) = sin(x)/x" );

$plot2->gnuplot_pause( 5);                     # hit RETURN to continue

$plot2->gnuplot_cmd( 'set terminal png color',
					 'set output "plot2.png" ' );  ##output to png###############################
$plot2->gnuplot_plot_equation(                # rewrite plot 2
	"y4(x) = 2*exp(-x)*sin(4*x)" );
	
$plot2->gnuplot_cmd( 'set output', 'set terminal x11');

$plot2->gnuplot_pause(5 );                     # hit RETURN to continue

my  $plot3  = GnuplotIF;                      # new plot object

my    @xyz    = (                             # 2-D-matrix, z-values
	[0,  1,  4,  9],
	[1,  2,  6, 15],
	[4,  6, 12, 27],
	[9, 15, 27, 54],
  );

$plot3->gnuplot_cmd( "set grid" );            # send a gnuplot command
$plot3->gnuplot_set_plot_titles("surface");   # set legend
$plot3->gnuplot_plot_3d( \@xyz );             # start 3-D-plot

				 

$plot3->gnuplot_pause(2 );                     # hit RETURN to continue
