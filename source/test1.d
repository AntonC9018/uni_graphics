import arsd.simpledisplay;
import common.util;

void main()
{
	auto window = new SimpleWindow();
	int width() { return window.width; }
	int height() { return window.height; }
	v2 dimensions() { return v2(width, height); }
	Point screenCenter() { return Point(width / 2, height / 2); }

	window.eventLoop(1000 / 60, 
	{
		auto painter = window.draw();
		painter.clear();
		painter.outlineColor = Color.black;
		painter.fillColor = Color.black;

		v2[4] points = [v2(0, 4), v2(-2, -1), v2(4, 2), v2(2, 2)];
		v2 start = v2(-4, -4);
		v2 end = v2(4, 4);
		v2 scaling = dimensions / (end - start);
		foreach (ref p; points)
			p = (p - start) * scaling;

		const pointWidth = 10;
		foreach (p; points)
			painter.drawCircle(p.point - pointWidth / 2, pointWidth);

		import common.bezier : getBezierPoint;
		v2 p0 = getBezierPoint(points, 0);
		for (float t = 0.01; t <= 1; t += 0.01)
		{
			v2 p1 = getBezierPoint(points, t);
			painter.drawLine(p0.point, p1.point); 
			p0 = p1;
		}

	});
}