import std.stdio;
import arsd.simpledisplay;

void main(string[] args)
{
	auto window = new SimpleWindow(400, 400);

	window.eventLoop(1000/60, {
		auto painter = window.draw();
		writeln("Hello");

		painter.outlineColor = Color.red;
		painter.fillColor = Color.black;
		painter.drawRectangle(Point(100, 100), 200, 200);
	});
}