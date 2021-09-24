import arsd.simpledisplay;

import std.range;
import std.algorithm;

import std.math;

import common.vector;
import common.csv;
	
void main(string[] args)
{
	auto window = new SimpleWindow();
	int width() { return window.width; }
	int height() { return window.height; }
	v2 dimensions() { return v2(width, height); }
	Point screenCenter() { return Point(width / 2, height / 2); }

	auto csv = loadCsv("income.csv");

	size_t findColumn(string name)
	{
		return csv.header.countUntil!(col => col == name);
	}

	size_t yearColumnIndex = findColumn("2020");
	assert(yearColumnIndex < csv.header.length);

	size_t startIndex = 50;
	size_t endIndex = 75;

	float[] values = new float[](endIndex - startIndex);

	foreach (index, ref value; values)
	{
		values[index] = csv.data[yearColumnIndex][index + startIndex].toFloatZero();
	}

	window.eventLoop(1000 / 60, {
		auto painter = window.draw();
		painter.clear(Color.white);
		painter.fillColor = Color.purple;
		// painter.outlineColor = Color.black;

		Pen pen;
		pen.style = Pen.Style.Solid;
		pen.width = 0;
		painter.pen = pen;

		enum leeway = 0.1;
		int width1 = cast(int) (min(width, height) * (1 - leeway));
		painter.drawArc(screenCenter - Point(width1 / 2, width1 / 2), width1, width1, -0, 90 * 64);
	});
}