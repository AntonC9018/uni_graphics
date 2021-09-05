import std.conv;
import std.stdio;

void main(string[] args)
{
	import arsd.simpledisplay;
	
	auto window = new SimpleWindow(400, 200);
	{ // introduce sub-scope
		auto painter = window.draw(); // begin drawing
		/* draw here */
		painter.outlineColor = Color.red;
		painter.fillColor = Color.black;
		painter.drawRectangle(Point(0, 0), 200, 200);
	} // end scope, calling `painter`'s destructor, drawing to the screen.
	window.eventLoop(0); // handle events
}