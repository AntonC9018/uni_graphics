import std.stdio;
import arsd.simpledisplay;

import std.range;
import std.algorithm;

import std.math;
import common.util;

v2[] samplePoints(float delegate(float) func, v2 rangeX, float numSamples)
{
	v2[] result;
	float step = (rangeX[1] - rangeX[0]) / numSamples;

	foreach (i; 0..numSamples)
	{
		float x = i * step + rangeX[0];
		result ~= v2(x, func(x)); 
	}

	result ~= v2(rangeX[1], func(rangeX[1]));

	return result;
}


float arctanh(float x, float epsilon)
{
	// It blows up to infinity at the endpoints.
	// I think it's not symmetric? 
	// I could do `x %= 1.0f` instead if it was though.
	if (x < -1 || x > 1) 
		return 0;

	float x_squared = x * x;
	float denominator = 1;
	float dx = x;
	float y = dx;

	// We bail out when the dx becomes too small to change the value significantly.
	// Now, the thing it, this Maclaurin series converges pretty slowly, so this is wrong.
	// Getting into more advanced equations does not seem like the point of the assignment,
	// so I shall stop here.
	while (abs(dx) > epsilon)
	{
		// x^(2k - 1) / (2k - 1)
		x *= x_squared;
		denominator += 2;
		dx = x / denominator;

		y += dx;
	}
	return y;
}

void writePointsComparisonCsv(string path, const v2[] samples, const v2[] referenceSamples, float epsilon)
{
	auto f = File(path, "w");
	f.writeln("x,y,reference_y,delta,epsilon");
	foreach (i, sample; samples)
	{
		f.writefln("%f,%f,%f,%8.8f,%f", sample.x, sample.y, referenceSamples[i].y, abs(sample.y - referenceSamples[i].y), epsilon);
	}
	f.close();
}

void writePointCsv(string path, const v2[] samples)
{
	auto f = File(path, "w");
	f.writeln("x,y");
	foreach (sample; samples)
	{
		f.writefln("%f,%f", sample.x, sample.y);
	}
	f.close();
}

void main(string[] args)
{
	auto window = new SimpleWindow();
	int width() { return window.width; }
	int height() { return window.height; }
	v2 dimensions() { return v2(width, height); }
	Point screenCenter() { return Point(width / 2, height / 2); }

	v2 rangeX = v2(-0.99, 0.99);

	int numSamples = 200;
	float epsilon = 0.0001f;
	const samples = samplePoints(a => arctanh(a, epsilon), rangeX, numSamples); 
	const referenceSamples = samplePoints(a => std.math.atanh(a), rangeX, numSamples); 

	void graph(const v2[] samples, ref ScreenPainter painter, v2 originInFuncCoords, v2 halfSpace) 
	{
		auto getPoint(v2 s) { return screenCenter + ((s - originInFuncCoords) * v2(1, -1) / halfSpace * dimensions / 2).point; }

		auto p0 = getPoint(samples[0]);
		foreach (s1; samples[1..$])
		{
			auto p1 = getPoint(s1);
			painter.drawLine(p0, p1);
			p0 = p1;
		}
	}

	writePointsComparisonCsv("atanh_comparison.csv", samples, referenceSamples, epsilon);
	writePointCsv("atanh.csv", samples);

	void draw()
	{	
		auto painter = window.draw();
		painter.clear();
		painter.outlineColor = Color.black;
		painter.fillColor = Color.black;
		
		painter.drawLine(Point(0, height / 2), Point(width, height / 2));
		painter.drawLine(Point(width / 2, 0), Point(width / 2, height));
		Pen pen;
		pen.width = 1;
		pen.color = Color.blue;
		pen.style = Pen.Style.Solid; 
		painter.pen = pen;

		auto maximumY = samples.fold!((a, el) => max(a, el.y))(-float.max);
		auto minimumY = samples.fold!((a, el) => min(a, el.y))(float.max);
		auto leeway = 0.1;

		auto rangeY = v2(minimumY, maximumY);
		auto origin = v2(rangeX[1] + rangeX[0], rangeY[1] + rangeY[0]) / 2;
		// auto start = (v2(rangeX[0], rangeY[0]) - origin) * (1 + leeway) + origin;
		// top tight corner coordinate in function coordinates
		auto end = (v2(rangeX[1], rangeY[1]) - origin) * (1 + leeway) + origin;

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
		
		graph(samples, painter, origin, halfSpace);
		pen.color = Color.red;
		painter.pen = pen;
		graph(referenceSamples, painter, origin, halfSpace);
	}

	window.eventLoop(1000/60, { draw(); });
}