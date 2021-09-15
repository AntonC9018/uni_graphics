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

	// result ~= v2(rangeX[1], func(rangeX[0]));

	return result;
}

auto epsilon = 0.0001f;

float arctanh(float x)
{
	// It blows up to infinity at the endpoints.
	// I think it's not symmetric? 
	// I could do `x %= 1.0f` instead if it was though.
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
	auto window = new SimpleWindow();
	auto width() { return window.width; }
	auto height() { return window.height; }
	v2 dimensions() { return v2(width, height); }
	v2 rangeX = v2(-0.99, 0.99);
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
		auto maximumY = samples.fold!((a, el) => max(a, el.y))(-float.max);
		auto minimumY = samples.fold!((a, el) => min(a, el.y))(float.max);
		auto leeway = 0.1;

		auto rangeY = v2(minimumY, maximumY);
		auto origin = v2(maximumY + minimumY, rangeX[1] + rangeX[0]) / 2;
		auto start = (v2(rangeX[0], rangeY[0]) - origin) * (1 + leeway) + origin;
		auto end = (v2(rangeX[1], rangeY[1]) - origin.y) * (1 + leeway) + origin.y;

		int numberOfpips = 10;
		int pipHeight = 10;
		int numberOfPipsPlus1 = numberOfpips + 1;
		v2 offsetScreen = v2(screenCenter.x / numberOfPipsPlus1, screenCenter.y / numberOfPipsPlus1);
		v2 halfSpace = end - origin;
		v2 individualOffset = halfSpace / numberOfPipsPlus1;

		foreach (i; -numberOfpips..numberOfpips + 1)
		{
			if (i == 0) continue;
			v2 p = origin + individualOffset * i;
			Point screenPoint = (offsetScreen * i).point;
			import std.conv, std.format;
			{
				// x pips
				Point screenStart = Point(screenPoint.x, -pipHeight / 2) + screenCenter;
				Point screenEnd = Point(screenPoint.x, pipHeight / 2) + screenCenter;
				painter.drawLine(screenStart, screenEnd);
				auto str = "%2.2f".format(p.x);
				painter.drawText(screenEnd - Point(painter.textSize(str).width / 2, 0), str);
			}
			{
				// y pips
				Point screenStart = Point(-pipHeight / 2, -screenPoint.y) + screenCenter;
				Point screenEnd = Point(pipHeight / 2, -screenPoint.y) + screenCenter;
				painter.drawLine(screenStart, screenEnd);
				auto str = "%2.2f".format(p.y);
				painter.drawText(screenEnd - Point(0, painter.textSize(str).height / 2), str);
			}
		}

		{
			auto getPoint(v2 s) { return screenCenter + (s / halfSpace * dimensions / 2).point; }
			auto p0 = getPoint(samples[0] * v2(1, -1));

			foreach (s1; samples[1..$])
			{
				auto p1 = getPoint(s1 * v2(1, -1));
				painter.drawLine(p0, p1);
				p0 = p1;
			}
		}
	}

	window.eventLoop(1000/60, { draw(); });
}