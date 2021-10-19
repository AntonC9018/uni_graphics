module bezier_editor;

import arsd.simpledisplay;
import common.bezier;
import common.util;
import std.stdio;
import std.algorithm;

void main()
{
	auto window = new SimpleWindow();
	int width() { return window.width; }
	int height() { return window.height; }
	v2 dimensions() { return v2(width, height); }
	Point screenCenter() { return Point(width / 2, height / 2); }
	
	v2[4] points = [v2(0, 0), v2(width / 2, 0), v2(width / 2, height / 2), v2(0, height / 2)];
	foreach (ref p; points)
		p += v2(width / 4, height / 4);

	int selectedIndex = -1;
	const int pointWidth = 10;

	window.eventLoop(1000/60,
	{	
		auto painter = window.draw();
		painter.clear();
		painter.outlineColor = Color.black;
		painter.fillColor = Color.black;

		foreach (p; points)
			painter.drawCircle(p.point - pointWidth / 2, pointWidth);

		v2 p0 = getBezierPoint(points, 0);
		for (float t = 0.01; t <= 1; t += 0.01)
		{
			v2 p1 = getBezierPoint(points, t);
			painter.drawLine(p0.point, p1.point); 
			p0 = p1;
		}
	}, (MouseEvent ev) 
	{
		switch (ev.type)
		{
			case MouseEventType.buttonReleased:
				selectedIndex = -1;
				return;
			case MouseEventType.buttonPressed:
			{
				auto mousePoint = v2(ev.x, ev.y);
				float minDistance = float.max;
				int minDistanceIndex = -1;
				foreach (index, p; points)
				{
					auto diff = mousePoint - p;
					auto distance = diff.sqMagnitude;
					if (distance < pointWidth^^2 && distance < minDistance)
					{
						minDistance = distance;
						minDistanceIndex = cast(int) index;
					}
				}
				selectedIndex = minDistanceIndex;
				return;
			}
			case MouseEventType.motion:
			{
				if (selectedIndex != -1)
					points[selectedIndex] = v2(ev.x, ev.y);
				return;
			}
			default: return;
		}
	});

	writeln(points[].map!(a => a.point));
}