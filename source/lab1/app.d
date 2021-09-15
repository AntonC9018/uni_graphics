import std.stdio;
import arsd.simpledisplay;

import std.range;
import std.algorithm;

import std.math;

struct v2
{
	float[2] arrayof;

	float x() const { return arrayof[0]; }
	float y() const { return arrayof[1]; }

	this(float x, float y)
	{
		arrayof[0] = x; 
		arrayof[1] = y;
	}

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

	ref auto opIndex(size_t index)
	{
		return arrayof[index];
	}
}

v2[] samplePoints(float delegate(float) func, v2 rangeX, float numSamples)
{
	v2[] result;
	float step = (rangeX[1] - rangeX[0]) / numSamples;

	foreach (i; 0..numSamples)
	{
		float x = i * step + rangeX[0];
		result ~= v2(x, func(x)); 
	}

	return result;
}

auto epsilon = 0.0001f;

float arctanh(float x)
{
	if (x < -1 || x > 1) 
		return 0;

	float x_squared = x * x;
	float denominator = 1;
	float dx = x;
	float y = 0;

	while (abs(dx) > epsilon)
	{
		y += dx;

		// x^(2k - 1) / (2k - 1)
		x *= x_squared;
		denominator += 2;
		dx = x / denominator;
	}
	return y;
}


void main(string[] args)
{
	auto window = new SimpleWindow(400, 400);

	int width = 400, height = 400;
	v2 dimensions = v2(width, height);
	v2 rangeX = v2(-1, 1);
	import std.functional : toDelegate;
	auto samples = samplePoints(toDelegate(&arctanh), rangeX, 200); 

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

		auto rangeY = v2(minimumY * (1 + leeway), maximumY * (1 + leeway));
		auto start = v2(rangeX[0], rangeY[0]);
		auto end = v2(rangeX[1], rangeY[1]);

		int numberOfpips = 10;
		int pipHeight = 10;
		v2 offsetScreen = v2(screenCenter.x / numberOfpips, screenCenter.y / numberOfpips);
		v2 origin = (start + end) / 2;
		v2 halfSpace = end - origin;
		v2 individualOffset = halfSpace / numberOfpips;

		foreach (i; -numberOfpips..numberOfpips)
		{
			if (i == 0) continue;
			v2 p = origin + individualOffset * i;
			Point screenPoint = (offsetScreen * i).point;
			import std.conv, std.format;
			{
				Point screenStart = Point(screenPoint.x, -pipHeight / 2) + screenCenter;
				Point screenEnd = Point(screenPoint.x, pipHeight / 2) + screenCenter;
				painter.drawLine(screenStart, screenEnd);
				auto str = "%1.1f".format(p.x);
				painter.drawText(screenEnd - Point(painter.textSize(str).width / 2, 0), str);
			}
			{
				Point screenStart = Point(-pipHeight / 2, -screenPoint.y) + screenCenter;
				Point screenEnd = Point(pipHeight / 2, -screenPoint.y) + screenCenter;
				painter.drawLine(screenStart, screenEnd);
				auto str = "%1.1f".format(p.y);
				painter.drawText(screenEnd - Point(0, painter.textSize(str).height / 2), str);
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