import std.stdio;
import arsd.simpledisplay;

import std.range;
import std.algorithm;

import std.math;

struct v2
{
	float x, y;

	Point point()
	{
		return Point(cast(int) x, cast(int) y);
	}

	v2 opBinary(string op)(const v2 rhs) const
	{
		mixin(`return v2(x`, op, `rhs.x,y`, op, `rhs.y);`);
	}

	v2 opBinary(string op)(const float rhs) const
	{
		mixin(`return v2(x`, op, `rhs,y`, op, `rhs);`);
	}
}

v2[] samplePoints(float delegate(float) func, float startX, float endX, float numSamples)
{
	v2[] result;
	float step = (endX - startX) / numSamples;

	foreach (i; 0..numSamples)
	{
		float x = i * step + startX;
		result ~= v2(x, func(x)); 
	}

	return result;
}

auto epsilon = 0.0001f;

float arctanh(float x)
{
	x = x % 1.0;
	float x2 = x * x;
	float dx = x;
	float below = 1;
	float y = x;
	while (dx > epsilon)
	{
		x *= x2;
		below += 2;
		dx = x / below;
		y += dx;
	}
	return y;
}


void main(string[] args)
{
	auto window = new SimpleWindow(400, 400);

	int width = 400, height = 400;
	v2 dimensions = v2(width, height);
	float startX = -1, endX = 1;
	import std.functional : toDelegate;
	auto samples = samplePoints(toDelegate(&arctanh), startX, endX, 200); 

	void draw()
	{	
		auto painter = window.draw();
		painter.clear();
		painter.outlineColor = Color.black;
		painter.fillColor = Color.black;

		Point screenCenter = Point(width / 2, height / 2);
		
		painter.drawLine(Point(0, height / 2), Point(width, height / 2));
		painter.drawLine(Point(width / 2, 0), Point(width / 2, height));

		Pen pen;
		pen.width = 1;
		pen.color = Color.blue;
		pen.style = Pen.Style.Solid; 

		painter.pen = pen;

		import std.algorithm.comparison : max, min;
		auto maximumY = samples.fold!((a, el) => max(a, el.y))(0.0f);
		auto minimumY = samples.fold!((a, el) => min(a, el.y))(float.max);
		auto leeway = 0.2;

		auto startY = minimumY * (1 + leeway);
		auto endY = maximumY * (1 + leeway);

		int numberOfpips = 10;
		int pipHeight = 10;
		v2 offsetScreen = v2(screenCenter.x / numberOfpips, screenCenter.y / numberOfpips);
		v2 origin = v2(endX + startX, startY + endY) / 2;
		v2 functionSpaceDims = v2(endX - startX, startY - endY);
		v2 halfSpace = v2(endX, endY) - origin;
		v2 individualOffset = halfSpace / numberOfpips;

		foreach (i; -numberOfpips..numberOfpips)
		{
			if (i == 0) continue;
			v2 p = origin + individualOffset * i;
			Point screenPoint = (offsetScreen * i).point;
			import std.conv, std.format;
			{
				Point start = Point(screenPoint.x, -pipHeight / 2) + screenCenter;
				Point end = Point(screenPoint.x, pipHeight / 2) + screenCenter;
				painter.drawLine(start, end);
				auto str = "%4.1f".format(p.x);
				painter.drawText(end - Point(painter.textSize(str).width / 2, 0), str);
			}
			{
				Point start = Point(-pipHeight / 2, -screenPoint.y) + screenCenter;
				Point end = Point(pipHeight / 2, -screenPoint.y) + screenCenter;
				painter.drawLine(start, end);
				auto str = "%4.1f".format(p.y);
				painter.drawText(end - Point(0, painter.textSize(str).height / 2), str);
			}
		}

		{
			auto getPoint(v2 s) { return screenCenter + (s / halfSpace * dimensions / 2).point; }
			auto p0 = getPoint(samples[0]);

			foreach (s1; samples[1..$])
			{
				auto p1 = getPoint(s1);
				painter.drawLine(p0, p1);
				p0 = p1;
			}
		}
	}

	window.eventLoop(1000/60, { draw(); });
}