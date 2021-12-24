import arsd.simpledisplay;
import common.util;
import std.stdio;

void main()
{
	auto window = new SimpleWindow();
	v2 dimensions() { return v2(window.width, window.height); }

	window.eventLoop(1000 / 60, 
	{
		auto painter = window.draw();
		painter.clear();
		painter.outlineColor = Color.black;
		painter.fillColor = Color.black;

		v2[4] points = [v2(3, 2), v2(2, -2), v2(-2, 3), v2(-1, -2)];
        bool mirrorY = true;
        if (mirrorY)
        {
            foreach (ref p; points)
                p.y = -p.y;
        }

		v2 start = v2(-4, -4);
		v2 end = v2(4, 4);
		v2 scaling = dimensions / (end - start);

		foreach (ref p; points)
			p = (p - start) * scaling;

		const pointWidth = 10;
		foreach (p; points)
			painter.drawCircle(p.point - pointWidth / 2, pointWidth);
		
        // Ecuația folosită în test 1
		import common.bezier : getBezierPoint;
		v2 p0 = points[0];
		for (float t = 0.01; t <= 1; t += 0.01)
		{
			v2 p1 = getBezierPoint(points, t);
			painter.drawLine(p0.point, p1.point); 
			p0 = p1;
		}
	});
}


void writePoints()
{
    v2[4] points = [v2(3, 2), v2(2, -2), v2(-2, 3), v2(-1, -2)];
    import common.bezier : getBezierPoint;
    v2 p0 = points[0];
    writeln("t,1-t,x,y");
    for (float t = 0; t <= 1.01; t += 0.05)
    {
        v2 p1 = getBezierPoint(points, t);
        writeln(t, ",", 1 - t, ",", p1.x, ",", p1.y);
        p0 = p1;
    }
}
